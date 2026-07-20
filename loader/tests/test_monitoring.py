from __future__ import annotations

import sys
import unittest
from datetime import datetime
from pathlib import Path
from uuid import uuid4

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.monitoring import write_load_batch, write_load_error


class FakeClient:
    def __init__(self) -> None:
        self.calls: list[dict] = []

    def insert(self, table, data, column_names) -> None:
        self.calls.append({"table": table, "data": data, "column_names": column_names})


class MonitoringTests(unittest.TestCase):
    def test_failed_batch_and_error_share_batch_id(self) -> None:
        client = FakeClient()
        run_id = uuid4()
        timestamp = datetime(2026, 1, 1)

        batch_id = write_load_batch(
            client=client,
            run_id=run_id,
            source_name="drivers.csv",
            target_database="raw",
            target_table="drivers",
            rows_loaded=0,
            started_at=timestamp,
            finished_at=timestamp,
            status="failed",
            error_message="invalid CSV",
        )
        write_load_error(
            client=client,
            run_id=run_id,
            batch_id=batch_id,
            source_name="drivers.csv",
            target_database="raw",
            target_table="drivers",
            error_message="invalid CSV",
            error_details="traceback",
        )

        self.assertEqual([call["table"] for call in client.calls], ["monitoring.load_batches", "monitoring.load_errors"])
        self.assertEqual(client.calls[1]["data"][0][2], str(batch_id))


if __name__ == "__main__":
    unittest.main()
