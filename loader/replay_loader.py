from __future__ import annotations

import argparse
import time
from pathlib import Path
from uuid import uuid4

import yaml

from src.clickhouse_client import get_client
from src.csv_utils import apply_table_specific_mapping, clean_dataframe, normalize_columns, read_csv, select_target_columns
from src.monitoring import utc_now, write_load_batch, write_pipeline_status


def iter_batches(df, batch_size: int):
    for start in range(0, len(df), batch_size):
        yield df.iloc[start : start + batch_size]


def load_event_table(client, raw_data_dir: Path, item: dict, run_id, batch_size: int, sleep_seconds: float) -> None:
    source_file = item["source_file"]
    target_database = item["target_database"]
    target_table = item["target_table"]
    full_table_name = f"{target_database}.{target_table}"

    path = raw_data_dir / source_file
    df = read_csv(path)
    df = normalize_columns(df)
    df = apply_table_specific_mapping(df, target_table)
    df = select_target_columns(df, target_table)
    df = clean_dataframe(df)

    print(f"Starting replay for {source_file}: {len(df)} rows")

    for batch_number, batch_df in enumerate(iter_batches(df, batch_size), start=1):
        started_at = utc_now()

        try:
            client.insert_df(full_table_name, batch_df)

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
                f"rows={len(batch_df)}, target={full_table_name}"
            )

        except Exception as exc:
            finished_at = utc_now()

            write_load_batch(
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

            raise

        time.sleep(sleep_seconds)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--table", default="lap_times", help="Table to replay: lap_times, pit_stops, results, qualifying, or all")
    parser.add_argument("--batch-size", type=int, default=None)
    parser.add_argument("--sleep-seconds", type=float, default=None)
    args = parser.parse_args()

    config_path = Path("/app/config.yaml")

    with config_path.open("r") as file:
        config = yaml.safe_load(file)

    raw_data_dir = Path(config["paths"]["raw_data_dir"])
    batch_size = args.batch_size or int(config["replay"]["batch_size"])
    sleep_seconds = args.sleep_seconds if args.sleep_seconds is not None else float(config["replay"]["sleep_seconds"])

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

    write_pipeline_status(
        client=client,
        component="replay_loader",
        status="started",
        message="Replay loading started",
        details=str(run_id),
    )

    for item in selected_tables:
        load_event_table(
            client=client,
            raw_data_dir=raw_data_dir,
            item=item,
            run_id=run_id,
            batch_size=batch_size,
            sleep_seconds=sleep_seconds,
        )

    write_pipeline_status(
        client=client,
        component="replay_loader",
        status="finished",
        message="Replay loading finished",
        details=str(run_id),
    )


if __name__ == "__main__":
    main()
