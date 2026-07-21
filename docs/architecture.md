# Architecture

## Overview

```text
F1 CSV Dataset
      ↓
Python Kafka Producer
      ↓
Apache Kafka
      ↓
ClickHouse Kafka Engine + Materialized Views
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

### Python Replay Producer

The data loading service. It reads historical Formula 1 event CSV data, normalizes rows, and publishes small batches to Kafka. Static dimension CSV files continue to load directly into ClickHouse.

### Apache Kafka

The asynchronous transport for event data. A local single-node KRaft broker stores replayed event messages until ClickHouse consumes them.

### ClickHouse Kafka Engine

Kafka-engine tables consume one topic per event type. Materialized views write the consumed rows into the existing `raw` tables, so dbt models keep their existing source contract.

### dbt

A data transformation tool. It is used to build staging, dwh, and marts layers.

### Superset

A BI tool for analytical dashboards covering races, drivers, teams, and results.

### Grafana

A monitoring tool for tracking data ingestion, pipeline state, and technical metrics.
