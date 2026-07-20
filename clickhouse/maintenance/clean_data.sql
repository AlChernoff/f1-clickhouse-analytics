-- This file is intentionally outside init/ so it is never run during startup.
TRUNCATE TABLE raw.drivers;
TRUNCATE TABLE raw.constructors;
TRUNCATE TABLE raw.circuits;
TRUNCATE TABLE raw.races;
TRUNCATE TABLE raw.results;
TRUNCATE TABLE raw.lap_times;
TRUNCATE TABLE raw.pit_stops;
TRUNCATE TABLE raw.qualifying;

TRUNCATE TABLE monitoring.load_batches;
TRUNCATE TABLE monitoring.load_errors;
TRUNCATE TABLE monitoring.pipeline_status;
TRUNCATE TABLE monitoring.loader_stats_1m;

DROP VIEW IF EXISTS dwh.stg_circuits;
DROP VIEW IF EXISTS dwh.stg_constructors;
DROP VIEW IF EXISTS dwh.stg_drivers;
DROP VIEW IF EXISTS dwh.stg_lap_times;
DROP VIEW IF EXISTS dwh.stg_pit_stops;
DROP VIEW IF EXISTS dwh.stg_qualifying;
DROP VIEW IF EXISTS dwh.stg_races;
DROP VIEW IF EXISTS dwh.stg_results;
DROP VIEW IF EXISTS dwh.dim_constructors;
DROP VIEW IF EXISTS dwh.dim_drivers;
DROP VIEW IF EXISTS dwh.dim_races;
DROP VIEW IF EXISTS dwh.fact_lap_times;
DROP VIEW IF EXISTS dwh.fact_pit_stops;
DROP VIEW IF EXISTS dwh.fact_race_results;

DROP VIEW IF EXISTS marts.mart_constructor_performance;
DROP VIEW IF EXISTS marts.mart_driver_performance;
DROP VIEW IF EXISTS marts.mart_lap_time_analysis;
DROP VIEW IF EXISTS marts.mart_pit_stop_efficiency;
DROP VIEW IF EXISTS marts.mart_season_summary;
