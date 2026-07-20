from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock
from uuid import uuid4

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.modules.setdefault("pandas", Mock())

from replay_loader import (  # noqa: E402
    load_event_table,
    non_negative_float,
    positive_int,
    validate_replay_settings,
)


class FakeClient:
    def __init__(self) -> None:
        self.calls: list[dict] = []

    def insert(self, table, data, column_names) -> None:
        self.calls.append({"table": table, "data": data, "column_names": column_names})

    def insert_df(self, table, dataframe) -> None:
        raise AssertionError("insert_df must not be called for a missing CSV")


class ReplayValidationTests(unittest.TestCase):
    def test_cli_validators_reject_invalid_values(self) -> None:
        with self.assertRaises(Exception):
            positive_int("0")
        with self.assertRaises(Exception):
            non_negative_float("-0.1")

    def test_config_validators_reject_invalid_values(self) -> None:
        with self.assertRaises(ValueError):
            validate_replay_settings(0, 0)
        with self.assertRaises(ValueError):
            validate_replay_settings(1, -1)

    def test_missing_csv_is_written_to_monitoring(self) -> None:
        client = FakeClient()
        item = {
            "source_file": "missing.csv",
            "target_database": "raw",
            "target_table": "drivers",
        }

        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(FileNotFoundError):
                load_event_table(client, Path(directory), item, uuid4(), 10, 0)

        self.assertEqual(
            [call["table"] for call in client.calls],
            ["monitoring.load_batches", "monitoring.load_errors"],
        )


if __name__ == "__main__":
    unittest.main()
