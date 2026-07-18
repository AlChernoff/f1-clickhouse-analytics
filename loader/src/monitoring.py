from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID, uuid4

from clickhouse_connect.driver.client import Client


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def write_load_batch(
    client: Client,
    run_id: UUID,
    source_name: str,
    target_database: str,
    target_table: str,
    rows_loaded: int,
    started_at: datetime,
    finished_at: datetime,
    status: str,
    error_message: str = "",
) -> None:
    duration_ms = int((finished_at - started_at).total_seconds() * 1000)

    client.insert(
        "monitoring.load_batches",
        [
            [
                str(uuid4()),
                str(run_id),
                source_name,
                target_database,
                target_table,
                rows_loaded,
                started_at,
                finished_at,
                duration_ms,
                status,
                error_message,
            ]
        ],
        column_names=[
            "batch_id",
            "run_id",
            "source_name",
            "target_database",
            "target_table",
            "rows_loaded",
            "started_at",
            "finished_at",
            "duration_ms",
            "status",
            "error_message",
        ],
    )


def write_pipeline_status(
    client: Client,
    component: str,
    status: str,
    message: str,
    details: str = "",
) -> None:
    client.insert(
        "monitoring.pipeline_status",
        [[utc_now(), component, status, message, details]],
        column_names=[
            "status_time",
            "component",
            "status",
            "message",
            "details",
        ],
    )
