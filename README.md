# F1 ClickHouse Analytics

Проект посвящен построению аналитической платформы для данных Формулы 1 на базе ClickHouse.

Исторический датасет гонок F1 загружается в ClickHouse небольшими порциями с задержкой, что имитирует поступление данных в реальном времени. ClickHouse используется для хранения raw-данных и агрегатов, dbt — для построения аналитических витрин, Superset — для BI-дашбордов, а Grafana — для мониторинга загрузки и состояния системы.

## Стек

- ClickHouse
- Python
- dbt
- Superset
- Grafana
- Docker Compose

## Архитектура

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