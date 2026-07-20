# F1 ClickHouse Analytics

This project focuses on building a ClickHouse-based analytics platform for Formula 1 data.

The historical F1 race dataset is loaded into ClickHouse in small delayed batches to simulate real-time event ingestion. ClickHouse is used to store raw data and aggregates, dbt is used to build analytical marts, Superset provides BI dashboards, and Grafana is used to monitor data loading and system health.

## Stack

- ClickHouse
- Python
- dbt
- Superset
- Grafana
- Docker Compose

## Architecture

```text
F1 CSV Dataset
      ↓
Python Replay Loader
      ↓
ClickHouse RAW Layer
      ↓
dbt Transformations
      ↓
ClickHouse MARTS
      ↓
Superset BI Dashboard
      ↓
Grafana Monitoring

## End-to-end demo

Required CSV files must be placed in `data/raw`.

Check input data:

    make check-data

Run the full local demo from scratch:

    make demo

Warning: `make demo` removes local Docker volumes and recreates the demo environment.

Useful URLs:

- Grafana: http://localhost:3000
- Superset: http://localhost:8088

Default local credentials:

- username: admin
- password: admin

## Demo flow

    CSV files
      -> Python replay loader
      -> ClickHouse raw layer
      -> dbt staging / dwh / marts
      -> Grafana monitoring
      -> Superset BI dashboard

