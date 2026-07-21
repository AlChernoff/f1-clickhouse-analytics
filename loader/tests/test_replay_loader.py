from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch
from uuid import uuid4

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.modules.setdefault("pandas", Mock())

from replay_loader import (  # noqa: E402
    EventTableConfig,
    load_event_table,
    non_negative_float,
    parse_replay_config,
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
    event_table = EventTableConfig(
        source_file="events.csv",
        target_database="raw",
        target_table="results",
    )

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
        event_table = EventTableConfig("missing.csv", "raw", "results")

        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(FileNotFoundError):
                load_event_table(client, Path(directory), event_table, uuid4(), 10, 0)

        self.assertEqual(
            [call["table"] for call in client.calls],
            ["monitoring.load_batches", "monitoring.load_errors"],
        )

    def test_event_replay_requires_kafka_producer(self) -> None:
        client = FakeClient()

        with tempfile.TemporaryDirectory() as directory:
            with patch("replay_loader.prepare_event_rows", return_value=[{"result_id": 1}]):
                with self.assertRaisesRegex(RuntimeError, "Kafka producer is required"):
                    load_event_table(
                        client,
                        Path(directory),
                        self.event_table,
                        uuid4(),
                        10,
                        0,
                        producer=None,
                    )

    def test_parse_replay_config_validates_and_types_values(self) -> None:
        config = {
            "paths": {"raw_data_dir": "/data/raw"},
            "replay": {"batch_size": "1000", "sleep_seconds": "0.1"},
            "event_tables": [
                {
                    "source_file": "events.csv",
                    "target_database": "raw",
                    "target_table": "results",
                }
            ],
        }

        replay_config = parse_replay_config(config)

        self.assertEqual(replay_config.batch_size, 1000)
        self.assertEqual(replay_config.event_tables[0], self.event_table)


if __name__ == "__main__":
    unittest.main()
