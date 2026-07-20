from __future__ import annotations

import traceback
from pathlib import Path
from uuid import uuid4

import yaml

from src.clickhouse_client import get_client
from src.csv_utils import apply_table_specific_mapping, clean_dataframe, normalize_columns, read_csv, select_target_columns
from src.monitoring import utc_now, write_load_batch, write_load_error, write_pipeline_status


def load_table(client, raw_data_dir: Path, item: dict, run_id) -> None:
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

        client.insert_df(full_table_name, df)

        finished_at = utc_now()

        write_load_batch(
            client=client,
            run_id=run_id,
            source_name=source_file,
            target_database=target_database,
            target_table=target_table,
            rows_loaded=len(df),
            started_at=started_at,
            finished_at=finished_at,
            status="success",
        )

        print(f"Loaded {len(df)} rows into {full_table_name}")

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
    config_path = Path("/app/config.yaml")

    with config_path.open("r") as file:
        config = yaml.safe_load(file)

    raw_data_dir = Path(config["paths"]["raw_data_dir"])
    run_id = uuid4()

    client = get_client()

    write_pipeline_status(
        client=client,
        component="load_static",
        status="started",
        message="Static data loading started",
        details=str(run_id),
    )

    try:
        for item in config["static_tables"]:
            load_table(client, raw_data_dir, item, run_id)
    except Exception as exc:
        write_pipeline_status(
            client=client,
            component="load_static",
            status="failed",
            message="Static data loading failed",
            details=f"run_id={run_id}; error={exc}",
        )
        raise
    else:
        write_pipeline_status(
            client=client,
            component="load_static",
            status="finished",
            message="Static data loading finished",
            details=str(run_id),
        )


if __name__ == "__main__":
    main()
