from __future__ import annotations

import argparse
import time
import traceback
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from uuid import uuid4

import yaml

from src.clickhouse_client import get_client
from src.csv_utils import (
    apply_table_specific_mapping,
    clean_dataframe,
    normalize_columns,
    read_csv,
    select_target_columns,
)
from src.kafka_producer import KafkaEventProducer
from src.monitoring import utc_now, write_load_batch, write_load_error, write_pipeline_status


@dataclass(frozen=True)
class EventTableConfig:
    source_file: str
    target_database: str
    target_table: str


@dataclass(frozen=True)
class ReplayConfig:
    raw_data_dir: Path
    batch_size: int
    sleep_seconds: float
    event_tables: tuple[EventTableConfig, ...]


def iter_batches(rows: list[dict], batch_size: int):
    for start in range(0, len(rows), batch_size):
        yield rows[start : start + batch_size]


def positive_int(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return parsed


def non_negative_float(value: str) -> float:
    parsed = float(value)
    if parsed < 0:
        raise argparse.ArgumentTypeError("must be zero or greater")
    return parsed


def validate_replay_settings(batch_size: int, sleep_seconds: float) -> None:
    if batch_size <= 0:
        raise ValueError("Replay batch size must be greater than zero")
    if sleep_seconds < 0:
        raise ValueError("Replay sleep seconds must be zero or greater")


def parse_replay_config(config: dict[str, Any]) -> ReplayConfig:
    try:
        event_tables = tuple(
            EventTableConfig(
                source_file=item["source_file"],
                target_database=item["target_database"],
                target_table=item["target_table"],
            )
            for item in config["event_tables"]
        )
        replay_config = ReplayConfig(
            raw_data_dir=Path(config["paths"]["raw_data_dir"]),
            batch_size=int(config["replay"]["batch_size"]),
            sleep_seconds=float(config["replay"]["sleep_seconds"]),
            event_tables=event_tables,
        )
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError("Invalid replay configuration") from exc

    validate_replay_settings(replay_config.batch_size, replay_config.sleep_seconds)
    return replay_config


def prepare_event_rows(raw_data_dir: Path, event_table: EventTableConfig) -> list[dict]:
    path = raw_data_dir / event_table.source_file
    dataframe = read_csv(path)
    dataframe = normalize_columns(dataframe)
    dataframe = apply_table_specific_mapping(dataframe, event_table.target_table)
    dataframe = select_target_columns(dataframe, event_table.target_table)
    return clean_dataframe(dataframe).to_dict(orient="records")


def load_event_table(
    client,
    raw_data_dir: Path,
    event_table: EventTableConfig,
    run_id,
    batch_size: int,
    sleep_seconds: float,
    producer: KafkaEventProducer | None = None,
) -> None:
    source_file = event_table.source_file
    target_database = event_table.target_database
    target_table = event_table.target_table
    full_table_name = f"{target_database}.{target_table}"

    started_at = utc_now()

    try:
        rows = prepare_event_rows(raw_data_dir, event_table)

        print(f"Starting replay for {source_file}: {len(rows)} rows")

        for batch_number, batch_rows in enumerate(iter_batches(rows, batch_size), start=1):
            started_at = utc_now()
            if producer is None:
                raise RuntimeError("Kafka producer is required for event replay")
            producer.publish_rows(
                target_table=target_table,
                rows=batch_rows,
                run_id=run_id,
                source_file=source_file,
                published_at=started_at,
            )
            finished_at = utc_now()
            write_load_batch(
                client=client,
                run_id=run_id,
                source_name=source_file,
                target_database=target_database,
                target_table=target_table,
                rows_loaded=len(batch_rows),
                started_at=started_at,
                finished_at=finished_at,
                status="success",
            )

            print(
                f"[{source_file}] batch={batch_number}, "
                f"rows={len(batch_rows)}, topic published for target={full_table_name}"
            )
            if sleep_seconds > 0 and batch_number * batch_size < len(rows):
                time.sleep(sleep_seconds)
    except Exception as exc:
        finished_at = utc_now()
        batch_id = write_load_batch(
            client=client,
            run_id=run_id,
            source_name=source_file,
            target_database=target_database,
            target_table=target_table,
            rows_loaded=0,
            started_at=started_at,
            finished_at=finished_at,
            status="failed",
            error_message=str(exc),
        )
        write_load_error(
            client=client,
            run_id=run_id,
            batch_id=batch_id,
            source_name=source_file,
            target_database=target_database,
            target_table=target_table,
            error_message=str(exc),
            error_details=traceback.format_exc(),
        )
        raise


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--table",
        default="lap_times",
        help="Table to replay: lap_times, pit_stops, results, qualifying, or all",
    )
    parser.add_argument("--batch-size", type=positive_int, default=None)
    parser.add_argument("--sleep-seconds", type=non_negative_float, default=None)
    args = parser.parse_args()

    config_path = Path("/app/config.yaml")

    with config_path.open("r") as file:
        config = yaml.safe_load(file)

    replay_config = parse_replay_config(config)
    batch_size = args.batch_size if args.batch_size is not None else replay_config.batch_size
    sleep_seconds = args.sleep_seconds if args.sleep_seconds is not None else replay_config.sleep_seconds
    validate_replay_settings(batch_size, sleep_seconds)

    selected_tables = replay_config.event_tables

    if args.table != "all":
        selected_tables = [
            event_table for event_table in selected_tables
            if event_table.target_table == args.table
        ]

    if not selected_tables:
        raise ValueError(f"No event table found for: {args.table}")

    run_id = uuid4()
    client = get_client()
    producer = KafkaEventProducer.from_environment()

    write_pipeline_status(
        client=client,
        component="replay_loader",
        status="started",
        message="Replay loading started",
        details=str(run_id),
    )

    try:
        for event_table in selected_tables:
            load_event_table(
                client=client,
                raw_data_dir=replay_config.raw_data_dir,
                event_table=event_table,
                run_id=run_id,
                batch_size=batch_size,
                sleep_seconds=sleep_seconds,
                producer=producer,
            )
    except Exception as exc:
        write_pipeline_status(
            client=client,
            component="replay_loader",
            status="failed",
            message="Replay loading failed",
            details=f"run_id={run_id}; error={exc}",
        )
        raise
    else:
        write_pipeline_status(
            client=client,
            component="replay_loader",
            status="finished",
            message="Replay loading finished",
            details=str(run_id),
        )


if __name__ == "__main__":
    main()
