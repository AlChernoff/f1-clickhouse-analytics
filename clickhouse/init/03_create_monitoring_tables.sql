CREATE TABLE IF NOT EXISTS monitoring.load_batches
(
    batch_id UUID,
    run_id UUID,
    source_name LowCardinality(String),
    target_database LowCardinality(String),
    target_table LowCardinality(String),
    rows_loaded UInt64,
    started_at DateTime64(3),
    finished_at DateTime64(3),
    duration_ms UInt64,
    status LowCardinality(String),
    error_message String,
    created_at DateTime DEFAULT now()
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(started_at)
ORDER BY (source_name, target_table, started_at, batch_id)
TTL toDateTime(started_at) + INTERVAL 30 DAY;

CREATE TABLE IF NOT EXISTS monitoring.load_errors
(
    error_id UUID,
    run_id UUID,
    batch_id Nullable(UUID),
    source_name LowCardinality(String),
    target_database LowCardinality(String),
    target_table LowCardinality(String),
    error_message String,
    error_details String,
    occurred_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(occurred_at)
ORDER BY (source_name, target_table, occurred_at, error_id)
TTL toDateTime(occurred_at) + INTERVAL 30 DAY;

CREATE TABLE IF NOT EXISTS monitoring.pipeline_status
(
    status_time DateTime64(3) DEFAULT now64(3),
    component LowCardinality(String),
    status LowCardinality(String),
    message String,
    details String
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(status_time)
ORDER BY (component, status_time)
TTL toDateTime(status_time) + INTERVAL 30 DAY;

CREATE TABLE IF NOT EXISTS monitoring.loader_stats_1m
(
    minute DateTime,
    source_name LowCardinality(String),
    target_table LowCardinality(String),
    rows_loaded UInt64,
    batches_count UInt64,
    success_count UInt64,
    failed_count UInt64,
    total_duration_ms UInt64
)
ENGINE = SummingMergeTree
PARTITION BY toYYYYMM(minute)
ORDER BY (source_name, target_table, minute);
