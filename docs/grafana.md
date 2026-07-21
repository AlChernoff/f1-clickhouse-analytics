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

- total rows published to Kafka;
- successful and failed batch counts;
- average batch duration;
- rows published and batches delivered per minute;
- average producer duration per minute;
- successful and failed producer batches per minute;
- latest producer batches and pipeline statuses.

`monitoring.load_batches` confirms delivery to Kafka. The **Producer to RAW
verification** section in `make demo-show` confirms that ClickHouse has consumed
the published event rows into the RAW layer.

## Source tables

The dashboard queries:

- `monitoring.load_batches`;
- `monitoring.loader_stats_1m`;
- `monitoring.pipeline_status`.
