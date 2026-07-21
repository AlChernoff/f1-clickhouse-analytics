from __future__ import annotations

import json
import sys
import unittest
from datetime import datetime
from pathlib import Path
from unittest.mock import patch
from uuid import uuid4

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.kafka_producer import KafkaEventProducer, message_key, normalize_row  # noqa: E402


class FakeProducer:
    def __init__(self, delivery_error=None, flush_result: int = 0, full_attempts: int = 0) -> None:
        self.calls: list[dict] = []
        self.delivery_error = delivery_error
        self.flush_result = flush_result
        self.full_attempts = full_attempts
        self.poll_calls: list[float] = []

    def produce(self, **kwargs) -> None:
        if self.full_attempts:
            self.full_attempts -= 1
            raise BufferError("queue full")
        self.calls.append(kwargs)
        kwargs["on_delivery"](self.delivery_error, None)

    def poll(self, _timeout: float) -> None:
        self.poll_calls.append(_timeout)

    def flush(self, _timeout: float) -> int:
        return self.flush_result


class KafkaEventProducerTests(unittest.TestCase):
    def test_key_is_stable_for_same_row(self) -> None:
        row = {"race_id": 1, "driver_id": 2, "lap": 3}
        self.assertEqual(message_key("lap_times", row), message_key("lap_times", row))

    def test_normalize_row_converts_nullable_integer_floats(self) -> None:
        row = normalize_row("results", {"result_id": 1.0, "position": None, "points": 10.0})
        self.assertEqual(row, {"result_id": 1, "position": None, "points": 10.0})

    def test_publish_rows_emits_clickhouse_compatible_messages_for_all_topics(self) -> None:
        rows = {
            "results": {"result_id": 1, "race_id": 1, "driver_id": 1, "constructor_id": 1},
            "qualifying": {"qualify_id": 1, "race_id": 1, "driver_id": 1, "constructor_id": 1},
            "lap_times": {"race_id": 1, "driver_id": 1, "lap": 1, "position": 1, "milliseconds": 80000},
            "pit_stops": {"race_id": 1, "driver_id": 1, "stop": 1, "lap": 1, "milliseconds": 20000},
        }

        for target_table, row in rows.items():
            with self.subTest(target_table=target_table):
                producer = FakeProducer()
                KafkaEventProducer(producer).publish_rows(
                    target_table=target_table,
                    rows=[row],
                    run_id=uuid4(),
                    source_file=f"{target_table}.csv",
                    published_at=datetime(2026, 7, 21, 12, 0, 0),
                )

                self.assertEqual(producer.calls[0]["topic"], f"f1.raw.{target_table.replace('_', '-')}.v1")
                payload = json.loads(producer.calls[0]["value"])
                self.assertIsInstance(payload["event_id"], str)
                self.assertIsInstance(payload["race_id"], int)

    def test_publish_rows_raises_for_delivery_error(self) -> None:
        event_producer = KafkaEventProducer(FakeProducer(delivery_error="broker unavailable"))

        with self.assertRaisesRegex(RuntimeError, "broker unavailable"):
            event_producer.publish_rows("results", [{"result_id": 1}], uuid4(), "results.csv", datetime.now())

    def test_publish_rows_raises_when_flush_times_out(self) -> None:
        event_producer = KafkaEventProducer(FakeProducer(flush_result=1))

        with self.assertRaisesRegex(TimeoutError, "did not deliver 1"):
            event_producer.publish_rows("results", [{"result_id": 1}], uuid4(), "results.csv", datetime.now())

    def test_publish_rows_retries_when_producer_queue_is_full(self) -> None:
        producer = FakeProducer(full_attempts=1)

        with patch("src.kafka_producer.time.sleep"):
            KafkaEventProducer(producer).publish_rows(
                "results", [{"result_id": 1}], uuid4(), "results.csv", datetime.now()
            )

        self.assertEqual(len(producer.calls), 1)
        self.assertIn(1, producer.poll_calls)


if __name__ == "__main__":
    unittest.main()
