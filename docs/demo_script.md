# Demo script

## Before the presentation

Place the eight required CSV files in `data/raw`, then run:

```bash
make demo
```

This command resets the local environment, shows Kafka topics, loads static data, publishes event data to Kafka, waits until ClickHouse consumes it, runs dbt, initializes Superset, imports the dashboard, and prints validation output. It removes local Docker volumes.

## During the presentation

Show the current state without changing data:

```bash
make demo-show
```

Then open:

- Grafana: <http://localhost:3000> → **F1 Analytics → F1 Loader Monitoring**;
- Superset: <http://localhost:8088> → **F1 Analytics Dashboard**.

## Talking points

1. Historical event CSV files are replayed in batches by the Python Kafka producer; ClickHouse consumes the corresponding topics into RAW tables.
2. ClickHouse stores raw data and loader monitoring events.
3. dbt builds staging, DWH, and mart views.
4. Grafana shows batch throughput, failures, and pipeline status.
5. Superset visualizes analytical marts.

For a manual step-by-step workflow, see [runbook.md](runbook.md).
