#!/usr/bin/env bash
set -euo pipefail

: "${CLICKHOUSE_USER:?CLICKHOUSE_USER must be set}"
: "${CLICKHOUSE_PASSWORD:?CLICKHOUSE_PASSWORD must be set}"

ch() {
  docker compose exec -T clickhouse clickhouse-client \
    --user "${CLICKHOUSE_USER}" \
    --password "${CLICKHOUSE_PASSWORD}" \
    "$@"
}

section() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

subsection() {
  echo ""
  echo "------------------------------------------------------------"
  echo "$1"
  echo "------------------------------------------------------------"
}

section "F1 ClickHouse Analytics Demo"

echo "Project pipeline:"
echo ""
echo "  CSV files"
echo "    -> Python replay loader"
echo "    -> ClickHouse raw layer"
echo "    -> dbt DWH and marts"
echo "    -> Grafana monitoring"
echo "    -> Superset BI dashboard"

section "1. Docker services"

docker compose ps

section "2. ClickHouse databases"

ch --query "
SELECT
    name AS database_name
FROM system.databases
WHERE name IN ('raw', 'dwh', 'marts', 'monitoring')
ORDER BY name
FORMAT PrettyCompact
"

section "3. Raw data row counts"

ch --query "
SELECT 'raw.drivers' AS table_name, count() AS rows_count FROM raw.drivers
UNION ALL
SELECT 'raw.constructors', count() FROM raw.constructors
UNION ALL
SELECT 'raw.circuits', count() FROM raw.circuits
UNION ALL
SELECT 'raw.races', count() FROM raw.races
UNION ALL
SELECT 'raw.results', count() FROM raw.results
UNION ALL
SELECT 'raw.lap_times', count() FROM raw.lap_times
UNION ALL
SELECT 'raw.pit_stops', count() FROM raw.pit_stops
UNION ALL
SELECT 'raw.qualifying', count() FROM raw.qualifying
FORMAT PrettyCompact
"

section "4. dbt marts"

ch --query "
SELECT
    database,
    name AS table_name,
    engine
FROM system.tables
WHERE database IN ('dwh', 'marts')
ORDER BY database, name
FORMAT PrettyCompact
"

section "5. Top drivers by total points"

ch --query "
SELECT
    driver_name,
    round(total_points, 2) AS total_points,
    wins,
    podiums,
    race_entries
FROM marts.mart_driver_performance
ORDER BY total_points DESC
LIMIT 10
FORMAT PrettyCompact
"

section "6. Top constructors by total points"

ch --query "
SELECT
    constructor_name,
    round(total_points, 2) AS total_points,
    wins,
    podiums,
    race_entries
FROM marts.mart_constructor_performance
ORDER BY total_points DESC
LIMIT 10
FORMAT PrettyCompact
"

section "7. Latest loader batches"

ch --query "
SELECT
    source_name,
    target_table,
    rows_loaded,
    duration_ms,
    status,
    formatDateTime(started_at, '%Y-%m-%d %H:%M:%S') AS started_at
FROM monitoring.load_batches
ORDER BY started_at DESC
LIMIT 10
FORMAT PrettyCompact
"

section "8. Loader summary"

ch --query "
SELECT
    count() AS total_batches,
    sum(rows_loaded) AS total_rows_loaded,
    countIf(status = 'success') AS successful_batches,
    countIf(status = 'failed') AS failed_batches,
    round(avg(duration_ms), 2) AS avg_duration_ms
FROM monitoring.load_batches
FORMAT PrettyCompact
"

section "9. Dashboards"

echo "Grafana monitoring:"
echo "  http://localhost:3000"
echo "  Dashboard: F1 Analytics -> F1 Loader Monitoring"
echo ""
echo "Superset BI:"
echo "  http://localhost:8088"
echo "  Dashboard: F1 Analytics Dashboard"
echo ""
echo "Local credentials:"
echo "  username: admin"
echo "  password: admin"

section "Demo is ready"
