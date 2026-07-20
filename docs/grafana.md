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
- batch error rate;
- failed pipeline runs in the selected time range;
- time of the last successful batch and last loader error;
- latest load batches, loader errors, and pipeline statuses.

The error-rate panel uses these thresholds:

- green: below 1%;
- orange: 1% to 5%;
- red: 5% or higher.

## Source tables

The dashboard queries:

- `monitoring.load_batches`;
- `monitoring.load_errors`;
- `monitoring.loader_stats_1m`;
- `monitoring.pipeline_status`.
