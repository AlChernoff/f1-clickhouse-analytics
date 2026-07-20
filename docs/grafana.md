# Grafana Monitoring

Grafana используется для мониторинга загрузки данных и состояния pipeline.

## Dashboard

Dashboard создается автоматически через provisioning.

Название:

F1 Loader Monitoring

Путь в Grafana:

Dashboards → F1 Analytics → F1 Loader Monitoring

## Datasource

Datasource ClickHouse создается автоматически из файла:

grafana/provisioning/datasources/clickhouse.yml

## Dashboard JSON

Dashboard хранится в файле:

grafana/dashboards/f1_loader_monitoring.json

## Метрики

Dashboard показывает:

- общее количество загруженных строк;
- количество успешных batch-загрузок;
- количество failed batch-загрузок;
- среднюю длительность batch-загрузки;
- rows loaded per minute;
- batches per minute;
- последние load batches;
- последние pipeline statuses.

## Source tables

Dashboard использует таблицы:

- monitoring.load_batches
- monitoring.loader_stats_1m
- monitoring.pipeline_status
