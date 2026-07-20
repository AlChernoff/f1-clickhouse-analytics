# Demo Script

This document describes the end-to-end demo flow for the F1 ClickHouse analytics project.

## What the demo shows

The demo shows a full analytical pipeline:

CSV files
  -> Python replay loader
  -> ClickHouse raw layer
  -> ClickHouse monitoring tables
  -> dbt staging / DWH / marts
  -> Grafana monitoring dashboard
  -> Superset BI dashboard

The project simulates real-time analytics by replaying historical Formula 1 CSV data into ClickHouse in batches.

## Data layers

The project uses several ClickHouse databases:

- raw: source data loaded from CSV files with minimal transformations.
- monitoring: technical metadata about loader runs, batches and pipeline statuses.
- dwh: cleaned analytical layer built by dbt. It contains staging models, dimensions and facts.
- marts: business-ready analytical tables built for dashboards.

DWH examples:

- dwh.dim_drivers
- dwh.dim_constructors
- dwh.dim_races
- dwh.fact_race_results
- dwh.fact_lap_times
- dwh.fact_pit_stops

Marts examples:

- marts.mart_driver_performance
- marts.mart_constructor_performance
- marts.mart_lap_time_analysis
- marts.mart_pit_stop_efficiency
- marts.mart_season_summary

Superset uses marts because they are already aggregated and ready for BI.

## Prerequisites

Required CSV files must be placed in:

data/raw

Required files:

- drivers.csv
- constructors.csv
- circuits.csv
- races.csv
- results.csv
- lap_times.csv
- pit_stops.csv
- qualifying.csv

## Full demo preparation

Warning: this command removes local Docker volumes and recreates the demo environment.

Run before the presentation:

make demo

The command performs:

1. stops containers and removes local volumes;
2. starts ClickHouse, Grafana and Superset;
3. checks that required CSV files exist;
4. loads static CSV data into ClickHouse;
5. replays event CSV data into ClickHouse in batches;
6. runs dbt transformations;
7. runs dbt tests;
8. initializes Superset;
9. imports the Superset dashboard;
10. prints basic validation queries.

## During the presentation

Use this command to show the current state without deleting or reloading data:

make demo-show

Then open Grafana:

http://localhost:3000

Dashboard:

F1 Analytics -> F1 Loader Monitoring

Then open Superset:

http://localhost:8088

Dashboard:

F1 Analytics Dashboard

## Step-by-step commands

Start infrastructure:

make up

Check services:

make ps

Check input data:

make check-data

Load static data:

make load-static

Replay event data:

make replay-pit-stops
make replay-lap-times
make replay-results
make replay-qualifying

Run dbt:

make dbt-run
make dbt-test

Show validation queries:

make demo-show

## Demo talking points

1. Show Docker Compose services.
2. Show ClickHouse databases: raw, dwh, marts and monitoring.
3. Explain Python replay loader and batch loading.
4. Show monitoring.load_batches and loader metrics.
5. Explain dbt layers:
   - staging cleans and deduplicates raw data;
   - DWH contains dimensions and facts;
   - marts contain BI-ready analytical tables.
6. Show Grafana monitoring dashboard.
7. Show Superset BI dashboard.
8. Explain deduplication strategy:
   - raw tables use ReplacingMergeTree;
   - dbt staging applies logical deduplication;
   - marts are used for BI.
