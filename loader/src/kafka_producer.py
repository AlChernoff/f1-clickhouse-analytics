from __future__ import annotations

import json
import os
import time
from datetime import date, datetime
from typing import Any
from uuid import UUID, uuid5

TOPICS = {
    "results": "f1.raw.results.v1",
    "qualifying": "f1.raw.qualifying.v1",
    "lap_times": "f1.raw.lap-times.v1",
    "pit_stops": "f1.raw.pit-stops.v1",
}

INTEGER_COLUMNS = {
    "results": {
        "result_id", "race_id", "driver_id", "constructor_id", "number", "grid", "position",
        "position_order", "laps", "milliseconds", "fastest_lap", "rank", "status_id",
    },
    "qualifying": {"qualify_id", "race_id", "driver_id", "constructor_id", "number", "position"},
    "lap_times": {"race_id", "driver_id", "lap", "position", "milliseconds"},
    "pit_stops": {"race_id", "driver_id", "stop", "lap", "milliseconds"},
}

EVENT_NAMESPACE = UUID("f2a0bf7c-0b1d-42ca-8ca6-7d9678ba8685")
MAX_PRODUCE_RETRIES = 3


def json_default(value: Any) -> str:
    if isinstance(value, date | datetime):
        return value.isoformat()
    if hasattr(value, "item"):
        return value.item()
    raise TypeError(f"Cannot serialize {type(value).__name__}")


def message_key(target_table: str, row: dict[str, Any]) -> str:
    serialized = json.dumps(row, sort_keys=True, default=json_default, separators=(",", ":"))
    return str(uuid5(EVENT_NAMESPACE, f"{target_table}:{serialized}"))


def normalize_row(target_table: str, row: dict[str, Any]) -> dict[str, Any]:
    integer_columns = INTEGER_COLUMNS[target_table]
    return {
        column: int(value) if column in integer_columns and value is not None else value
        for column, value in row.items()
    }


class KafkaEventProducer:
    def __init__(self, producer: Any) -> None:
        self.producer = producer
        self.delivery_errors: list[str] = []

    @classmethod
    def from_environment(cls) -> KafkaEventProducer:
        from confluent_kafka import Producer

        bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
        producer = Producer(
            {
                "bootstrap.servers": bootstrap_servers,
                "client.id": os.getenv("KAFKA_CLIENT_ID", "f1-replay-loader"),
                "acks": "all",
                "enable.idempotence": True,
            }
        )
        return cls(producer)

    def publish_rows(
        self,
        target_table: str,
        rows: list[dict[str, Any]],
        run_id: UUID,
        source_file: str,
        published_at: datetime,
    ) -> None:
        try:
            topic = TOPICS[target_table]
        except KeyError as exc:
            raise ValueError(f"No Kafka topic configured for event table: {target_table}") from exc

        self.delivery_errors = []
        published_at_value = published_at.strftime("%Y-%m-%d %H:%M:%S.%f")

        for row in rows:
            row = normalize_row(target_table, row)
            key = message_key(target_table, row)
            message = {
                "event_id": key,
                "run_id": str(run_id),
                "source_file": source_file,
                "published_at": published_at_value,
                **row,
            }
            self._produce(topic, key, message)
            self.producer.poll(0)

        outstanding = self.producer.flush(30)
        if outstanding:
            raise TimeoutError(f"Kafka producer did not deliver {outstanding} message(s) to {topic}")
        if self.delivery_errors:
            raise RuntimeError("Kafka delivery failed: " + "; ".join(self.delivery_errors))

    def _produce(self, topic: str, key: str, message: dict[str, Any]) -> None:
        for attempt in range(1, MAX_PRODUCE_RETRIES + 1):
            try:
                self.producer.produce(
                    topic=topic,
                    key=key.encode(),
                    value=json.dumps(message, default=json_default).encode(),
                    on_delivery=self._on_delivery,
                )
                return
            except BufferError:
                if attempt == MAX_PRODUCE_RETRIES:
                    raise TimeoutError(
                        f"Kafka producer queue remained full after {MAX_PRODUCE_RETRIES} attempts"
                    ) from None
                self.producer.poll(1)
                time.sleep(0.1)

    def _on_delivery(self, error: Any, _message: Any) -> None:
        if error is not None:
            self.delivery_errors.append(str(error))
