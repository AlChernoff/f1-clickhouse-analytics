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
