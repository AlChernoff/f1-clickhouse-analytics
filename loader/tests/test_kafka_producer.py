from __future__ import annotations

import json
import sys
import unittest
from datetime import datetime
from pathlib import Path
from uuid import uuid4

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.kafka_producer import KafkaEventProducer, message_key, normalize_row  # noqa: E402


class FakeProducer:
    def __init__(self) -> None:
        self.calls: list[dict] = []

    def produce(self, **kwargs) -> None:
        self.calls.append(kwargs)
        kwargs["on_delivery"](None, None)

    def poll(self, _timeout: float) -> None:
        return None

    def flush(self, _timeout: float) -> int:
        return 0


class KafkaEventProducerTests(unittest.TestCase):
    def test_key_is_stable_for_same_row(self) -> None:
        row = {"race_id": 1, "driver_id": 2, "lap": 3}
        self.assertEqual(message_key("lap_times", row), message_key("lap_times", row))

    def test_normalize_row_converts_nullable_integer_floats(self) -> None:
        row = normalize_row("results", {"result_id": 1.0, "position": None, "points": 10.0})
        self.assertEqual(row, {"result_id": 1, "position": None, "points": 10.0})

    def test_publish_rows_emits_clickhouse_compatible_message(self) -> None:
        producer = FakeProducer()
        event_producer = KafkaEventProducer(producer)
        run_id = uuid4()

        event_producer.publish_rows(
            target_table="lap_times",
            rows=[{"race_id": 1, "driver_id": 2, "lap": 3, "position": 1, "lap_time": "1:20", "milliseconds": 80000}],
            run_id=run_id,
            source_file="lap_times.csv",
            published_at=datetime(2026, 7, 21, 12, 0, 0),
        )

        self.assertEqual(producer.calls[0]["topic"], "f1.raw.lap-times.v1")
        payload = json.loads(producer.calls[0]["value"])
        self.assertEqual(payload["run_id"], str(run_id))
        self.assertEqual(payload["race_id"], 1)
        self.assertIsInstance(payload["race_id"], int)
        self.assertIn("event_id", payload)


if __name__ == "__main__":
    unittest.main()
