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

section "F1 ClickHouse Analytics Demo"

echo "Project pipeline:"
echo ""
echo "  CSV files"
echo "    -> Python Kafka producer"
echo "    -> Apache Kafka"
echo "    -> ClickHouse Kafka Engine"
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

section "3. RAW data row counts"

ch --query "
SELECT table_name, rows_count
FROM
(
    SELECT 1 AS sort_order, 'raw.drivers' AS table_name, count() AS rows_count FROM raw.drivers
    UNION ALL
    SELECT 2, 'raw.constructors', count() FROM raw.constructors
    UNION ALL
    SELECT 3, 'raw.circuits', count() FROM raw.circuits
    UNION ALL
    SELECT 4, 'raw.races', count() FROM raw.races
    UNION ALL
    SELECT 5, 'raw.results', count() FROM raw.results
    UNION ALL
    SELECT 6, 'raw.qualifying', count() FROM raw.qualifying
    UNION ALL
    SELECT 7, 'raw.lap_times', count() FROM raw.lap_times
    UNION ALL
    SELECT 8, 'raw.pit_stops', count() FROM raw.pit_stops
)
ORDER BY sort_order
FORMAT PrettyCompact
"

section "4. Producer to RAW verification"

ch --query "
SELECT
    published.target_table,
    published.rows_published,
    raw.rows_in_raw,
    published.rows_published = raw.rows_in_raw AS rows_match
FROM
(
    SELECT target_table, sum(rows_loaded) AS rows_published
    FROM monitoring.load_batches
    WHERE status = 'success'
      AND target_table IN ('results', 'qualifying', 'lap_times', 'pit_stops')
    GROUP BY target_table
) AS published
INNER JOIN
(
    SELECT 'results' AS target_table, count() AS rows_in_raw FROM raw.results
    UNION ALL SELECT 'qualifying', count() FROM raw.qualifying
    UNION ALL SELECT 'lap_times', count() FROM raw.lap_times
    UNION ALL SELECT 'pit_stops', count() FROM raw.pit_stops
) AS raw USING target_table
ORDER BY indexOf(['results', 'qualifying', 'lap_times', 'pit_stops'], published.target_table)
FORMAT PrettyCompact
"

section "5. dbt marts"

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

section "6. Top drivers by total points"

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

section "7. Top constructors by total points"

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

section "8. Latest producer batches"

ch --query "
SELECT
    source_name,
    target_table,
    rows_loaded AS rows_published,
    duration_ms,
    status,
    formatDateTime(started_at, '%F %T') AS started_at
FROM monitoring.load_batches
ORDER BY started_at DESC
LIMIT 10
FORMAT PrettyCompact
"

section "9. Producer summary"

ch --query "
SELECT
    count() AS total_batches,
    sum(rows_loaded) AS total_rows_published,
    countIf(status = 'success') AS successful_batches,
    countIf(status = 'failed') AS failed_batches,
    round(avg(duration_ms), 2) AS avg_duration_ms
FROM monitoring.load_batches
FORMAT PrettyCompact
"

section "10. Dashboards"

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
