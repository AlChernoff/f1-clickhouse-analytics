CREATE MATERIALIZED VIEW IF NOT EXISTS monitoring.mv_loader_stats_1m
TO monitoring.loader_stats_1m
AS
SELECT
    toStartOfMinute(started_at) AS minute,
    source_name,
    target_table,
    sum(rows_loaded) AS rows_loaded,
    count() AS batches_count,
    countIf(status = 'success') AS success_count,
    countIf(status = 'failed') AS failed_count,
    sum(duration_ms) AS total_duration_ms
FROM monitoring.load_batches
GROUP BY
    minute,
    source_name,
    target_table;
