# Grafana monitoring

Grafana monitors data ingestion and pipeline health.

## Dashboard

The dashboard is provisioned automatically.

Name:

**F1 Loader Monitoring**

Grafana path:

**Dashboards → F1 Analytics → F1 Loader Monitoring**

## Data source

The ClickHouse data source is provisioned from:

`grafana/provisioning/datasources/clickhouse.yml`

## Dashboard definition

The dashboard JSON is stored in:

`grafana/dashboards/f1_loader_monitoring.json`

## Metrics and widgets

The dashboard shows:

- total loaded rows;
- successful and failed batch counts;
- average batch duration;
- rows and batches loaded per minute;
- latest producer batches and pipeline statuses.

## Source tables

The dashboard queries:

- `monitoring.load_batches`;
- `monitoring.loader_stats_1m`;
- `monitoring.pipeline_status`.
