#!/usr/bin/env bash
set -euo pipefail

SOURCE_ZIP="/app/project_superset/dashboards/f1_dashboard.zip"
PATCHED_ZIP="/tmp/f1_dashboard_import.zip"

CLICKHOUSE_USER="${CLICKHOUSE_USER:-f1_app}"
CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD:-f1_app_password}"
CLICKHOUSE_HOST="${CLICKHOUSE_HOST:-clickhouse}"
CLICKHOUSE_HTTP_PORT="${CLICKHOUSE_HTTP_PORT:-8123}"
CLICKHOUSE_DATABASE="${CLICKHOUSE_DATABASE:-marts}"
SUPERSET_ADMIN_USER="${SUPERSET_ADMIN_USER:-admin}"

python - <<PY
import zipfile
from pathlib import Path

source_zip = Path("${SOURCE_ZIP}")
patched_zip = Path("${PATCHED_ZIP}")

if not source_zip.exists():
    raise FileNotFoundError(f"Dashboard export not found: {source_zip}")

old_uri = "clickhousedb://f1_app:XXXXXXXXXX@clickhouse:8123/marts"
new_uri = "clickhousedb://${CLICKHOUSE_USER}:${CLICKHOUSE_PASSWORD}@${CLICKHOUSE_HOST}:${CLICKHOUSE_HTTP_PORT}/${CLICKHOUSE_DATABASE}"

with zipfile.ZipFile(source_zip, "r") as zin:
    with zipfile.ZipFile(patched_zip, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename.endswith(".yaml"):
                text = data.decode("utf-8")
                text = text.replace(old_uri, new_uri)
                data = text.encode("utf-8")
            zout.writestr(item, data)

print(f"Created patched Superset dashboard import: {patched_zip}")
PY

superset import-dashboards -p "${PATCHED_ZIP}" -u "${SUPERSET_ADMIN_USER}"
