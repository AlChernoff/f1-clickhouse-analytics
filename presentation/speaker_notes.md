# Текст защиты: F1 ClickHouse Analytics

## Слайд 1. Тема проекта
Здравствуйте. Тема моего проекта — **F1 ClickHouse Analytics**: локальная аналитическая платформа для данных Формулы 1.

Идея проекта — взять исторический датасет и загружать его не одним большим импортом, а в режиме replay. После добавления Kafka поток выглядит ближе к реальному сценарию: Python producer публикует события в Kafka, ClickHouse потребляет их через Kafka Engine, а дальше строятся аналитические слои и дашборды.

В проекте используются ClickHouse, Kafka, dbt, Grafana, Superset, Python и Docker Compose.

## Слайд 2. Цель и задачи проекта
Цель проекта — построить воспроизводимый pipeline для real-time-like аналитики Формулы 1 на базе ClickHouse.

Задачи были такие:

1. Поднять инфраструктуру локально через Docker Compose.
2. Организовать загрузку данных: справочники напрямую в ClickHouse, событийные таблицы через Kafka.
3. Построить raw, monitoring, dwh и marts слои.
4. Добавить dbt-трансформации и тесты качества данных.
5. Настроить Grafana для технического мониторинга и Superset для бизнес-аналитики.
6. Сделать demo-команды, чтобы проект можно было воспроизвести с нуля.

## Слайд 3. Технологии и роли компонентов
В проекте каждая технология отвечает за отдельную часть pipeline.

Python и uv используются для loader-а: чтение CSV, нормализация, публикация сообщений в Kafka и запись технических метрик.

Kafka используется как асинхронный буфер событий. Это делает проект ближе к реальному ingestion-сценарию: данные сначала попадают в topic-и, а затем потребляются ClickHouse.

ClickHouse — центральное аналитическое хранилище. Он хранит raw-данные, monitoring-таблицы, DWH и marts. Для потребления Kafka используются Kafka Engine tables и materialized views.

dbt строит staging, dimensions, facts и marts, а также запускает data-quality tests.

Grafana показывает технический мониторинг загрузки, Superset — бизнесовые дашборды.

## Слайд 4. Архитектура решения
Архитектура теперь выглядит так:

CSV-датасет читается Python producer-ом. Для событийных таблиц producer публикует батчи в Kafka. ClickHouse Kafka Engine читает данные из topic-ов, а materialized views записывают их в raw-таблицы.

Справочники, например drivers, constructors, races, загружаются напрямую в raw.

После raw-слоя dbt строит DWH и marts. Grafana читает monitoring-таблицы, а Superset подключается к marts.

Главная идея: мы не просто импортируем CSV, а показываем полный ingestion pipeline: source → Kafka → ClickHouse → transformations → dashboards.

## Слайд 5. ClickHouse: слои данных и дедубликация
В ClickHouse есть несколько логических слоев.

**raw** — слой исходных данных. Таблицы используют ReplacingMergeTree с `loaded_at` как version column.

**monitoring** — технические таблицы: `load_batches`, `pipeline_status`, агрегаты по минутам.

**dwh** — слой dbt с очищенными staging-моделями, dimensions и facts.

**marts** — готовые аналитические таблицы для Superset.

Дедубликация сделана в два уровня. На уровне ClickHouse ReplacingMergeTree может схлопывать версии записей по business key во время background merges. Но это не строгий unique constraint, поэтому dbt staging дополнительно применяет логическую дедубликацию через `row_number()` по бизнес-ключам. Это гарантирует, что marts будут чистыми для BI.

## Слайд 6. Kafka ingestion и monitoring
После добавления Kafka мониторинг стал важной частью проекта.

Grafana показывает, сколько строк загружено, сколько batch-ей прошло успешно, были ли ошибки, среднюю длительность batch-а и статус pipeline.

Также в проекте есть команды для проверки Kafka:

- `make kafka-topics` — посмотреть topic-и;
- `make kafka-consumers` — проверить состояние ClickHouse consumers;
- `make demo-show` — получить красивый терминальный отчет по состоянию проекта.

Grafana datasource и dashboard описаны как code и поднимаются автоматически.

## Слайд 7. BI dashboard и demo flow
Superset используется для бизнес-аналитики. Он не читает raw-таблицы напрямую, а подключается к готовым marts.

В дашборде есть:

- топ пилотов по очкам;
- топ команд по очкам;
- динамика сезонов;
- таблицы побед и подиумов;
- анализ пит-стопов;
- анализ лучших кругов.

Для проверки проекта есть команда `make demo`. Она пересоздает локальное окружение, загружает данные, публикует события в Kafka, ждет consumption в ClickHouse, запускает dbt и импортирует dashboard в Superset.

На самой защите удобнее заранее выполнить `make demo`, а в live-режиме показать `make demo-show`, Grafana и Superset.

## Слайд 8. Итоги и развитие
В итоге получился воспроизводимый локальный data platform demo:

- данные Формулы 1 загружаются через Kafka-backed replay;
- ClickHouse хранит raw, monitoring, dwh и marts;
- dbt строит аналитические модели и тестирует качество данных;
- Grafana показывает технический мониторинг;
- Superset показывает BI-дашборд;
- проект можно поднять командой `make demo`.

Самыми сложными частями были: типы исторических дат, права пользователей ClickHouse, импорт Superset dashboard и настройка Kafka consumption.

Дальше можно развивать проект: добавить Prometheus/exporters для инфраструктурных метрик, Airflow для orchestration, Schema Registry для контрактов событий Kafka и alerts по consumer lag или failed batches.

## Короткий план live-demo

1. Показать репозиторий и README.
2. Выполнить `make demo-show`.
3. Открыть Grafana: `http://localhost:3000`.
4. Открыть Superset: `http://localhost:8088`.
5. Показать ключевые ClickHouse таблицы: raw, monitoring, marts.
6. Ответить на вопросы по Kafka, ReplacingMergeTree и dbt-дедубликации.
