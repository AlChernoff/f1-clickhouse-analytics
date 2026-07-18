from __future__ import annotations

import os
import time
from typing import Any

import clickhouse_connect


def get_client() -> Any:
    host = os.getenv("CLICKHOUSE_HOST", "clickhouse")
    port = int(os.getenv("CLICKHOUSE_HTTP_PORT", "8123"))
    username = os.getenv("CLICKHOUSE_USER", "default")
    password = os.getenv("CLICKHOUSE_PASSWORD", "")

    last_error: Exception | None = None

    for attempt in range(1, 11):
        try:
            return clickhouse_connect.get_client(
                host=host,
                port=port,
                username=username,
                password=password,
            )
        except Exception as exc:
            last_error = exc
            print(
                f"ClickHouse HTTP is not ready yet "
                f"(attempt {attempt}/10): host={host}, port={port}, error={exc}"
            )
            time.sleep(2)

    raise RuntimeError(
        f"Could not connect to ClickHouse via HTTP: host={host}, port={port}"
    ) from last_error
