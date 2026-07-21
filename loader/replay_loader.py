from __future__ import annotations

import argparse
import time
import traceback
from pathlib import Path
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


def iter_batches(df, batch_size: int):
    for start in range(0, len(df), batch_size):
        yield df.iloc[start : start + batch_size]


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


def load_event_table(
    client,
    raw_data_dir: Path,
    item: dict,
    run_id,
    batch_size: int,
    sleep_seconds: float,
    producer: KafkaEventProducer | None = None,
) -> None:
    source_file = item["source_file"]
    target_database = item["target_database"]
    target_table = item["target_table"]
    full_table_name = f"{target_database}.{target_table}"

    started_at = utc_now()

    try:
        path = raw_data_dir / source_file
        df = read_csv(path)
        df = normalize_columns(df)
        df = apply_table_specific_mapping(df, target_table)
        df = select_target_columns(df, target_table)
        df = clean_dataframe(df)

        print(f"Starting replay for {source_file}: {len(df)} rows")

        for batch_number, batch_df in enumerate(iter_batches(df, batch_size), start=1):
            started_at = utc_now()
            if producer is None:
                raise RuntimeError("Kafka producer is required for event replay")
            producer.publish_rows(
                target_table=target_table,
                rows=batch_df.to_dict(orient="records"),
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
                rows_loaded=len(batch_df),
                started_at=started_at,
                finished_at=finished_at,
                status="success",
            )

            print(
                f"[{source_file}] batch={batch_number}, "
                f"rows={len(batch_df)}, topic published for target={full_table_name}"
            )
            if sleep_seconds > 0 and batch_number * batch_size < len(df):
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

    raw_data_dir = Path(config["paths"]["raw_data_dir"])
    batch_size = args.batch_size if args.batch_size is not None else int(config["replay"]["batch_size"])
    sleep_seconds = args.sleep_seconds if args.sleep_seconds is not None else float(config["replay"]["sleep_seconds"])
    validate_replay_settings(batch_size, sleep_seconds)

    selected_tables = config["event_tables"]

    if args.table != "all":
        selected_tables = [
            item for item in selected_tables
            if item["target_table"] == args.table
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
        for item in selected_tables:
            load_event_table(
                client=client,
                raw_data_dir=raw_data_dir,
                item=item,
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
