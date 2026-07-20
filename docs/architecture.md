# Architecture

## Overview

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
```

## Components

### ClickHouse

The main analytical data store of the project. It is used for raw data, analytical marts, aggregates, and monitoring tables.

### Python Replay Loader

The data loading service. It reads historical Formula 1 CSV data and loads it into ClickHouse in small batches, simulating real-time event ingestion.

### dbt

A data transformation tool. It is used to build staging, dwh, and marts layers.

### Superset

A BI tool for analytical dashboards covering races, drivers, teams, and results.

### Grafana

A monitoring tool for tracking data ingestion, pipeline state, and technical metrics.
