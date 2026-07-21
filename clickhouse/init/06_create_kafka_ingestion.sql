CREATE DATABASE IF NOT EXISTS kafka_ingestion;

CREATE TABLE IF NOT EXISTS kafka_ingestion.results
(
    event_id UUID,
    run_id UUID,
    source_file String,
    published_at DateTime64(3),
    result_id UInt32, race_id UInt32, driver_id UInt32, constructor_id UInt32,
    number Nullable(UInt16), grid Int16, position Nullable(UInt8), position_text Nullable(String),
    position_order UInt8, points Float32, laps UInt16, time Nullable(String), milliseconds Nullable(UInt32),
    fastest_lap Nullable(UInt16), rank Nullable(UInt8), fastest_lap_time Nullable(String),
    fastest_lap_speed Nullable(Float32), status_id UInt32
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:9092', kafka_topic_list = 'f1.raw.results.v1',
    kafka_group_name = 'f1-clickhouse-results-v1', kafka_format = 'JSONEachRow', kafka_num_consumers = 1;

CREATE MATERIALIZED VIEW IF NOT EXISTS kafka_ingestion.results_to_raw TO raw.results AS
SELECT result_id, race_id, driver_id, constructor_id, number, grid, position, position_text,
    position_order, points, laps, time, milliseconds, fastest_lap, rank, fastest_lap_time,
    fastest_lap_speed, status_id
FROM kafka_ingestion.results;

CREATE TABLE IF NOT EXISTS kafka_ingestion.qualifying
(
    event_id UUID, run_id UUID, source_file String, published_at DateTime64(3),
    qualify_id UInt32, race_id UInt32, driver_id UInt32, constructor_id UInt32,
    number UInt16, position UInt8, q1 Nullable(String), q2 Nullable(String), q3 Nullable(String)
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:9092', kafka_topic_list = 'f1.raw.qualifying.v1',
    kafka_group_name = 'f1-clickhouse-qualifying-v1', kafka_format = 'JSONEachRow', kafka_num_consumers = 1;

CREATE MATERIALIZED VIEW IF NOT EXISTS kafka_ingestion.qualifying_to_raw TO raw.qualifying AS
SELECT qualify_id, race_id, driver_id, constructor_id, number, position, q1, q2, q3
FROM kafka_ingestion.qualifying;

CREATE TABLE IF NOT EXISTS kafka_ingestion.lap_times
(
    event_id UUID, run_id UUID, source_file String, published_at DateTime64(3),
    race_id UInt32, driver_id UInt32, lap UInt16, position UInt8, lap_time String, milliseconds UInt32
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:9092', kafka_topic_list = 'f1.raw.lap-times.v1',
    kafka_group_name = 'f1-clickhouse-lap-times-v1', kafka_format = 'JSONEachRow', kafka_num_consumers = 1;

CREATE MATERIALIZED VIEW IF NOT EXISTS kafka_ingestion.lap_times_to_raw TO raw.lap_times AS
SELECT race_id, driver_id, lap, position, lap_time, milliseconds
FROM kafka_ingestion.lap_times;

CREATE TABLE IF NOT EXISTS kafka_ingestion.pit_stops
(
    event_id UUID, run_id UUID, source_file String, published_at DateTime64(3),
    race_id UInt32, driver_id UInt32, stop UInt8, lap UInt16, pit_time String, duration String, milliseconds UInt32
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:9092', kafka_topic_list = 'f1.raw.pit-stops.v1',
    kafka_group_name = 'f1-clickhouse-pit-stops-v1', kafka_format = 'JSONEachRow', kafka_num_consumers = 1;

CREATE MATERIALIZED VIEW IF NOT EXISTS kafka_ingestion.pit_stops_to_raw TO raw.pit_stops AS
SELECT race_id, driver_id, stop, lap, pit_time, duration, milliseconds
FROM kafka_ingestion.pit_stops;
