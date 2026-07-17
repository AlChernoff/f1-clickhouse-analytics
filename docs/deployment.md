# Deployment

## Требования

- Docker
- Docker Compose
- make

## Запуск

cp .env.example .env
make up

## Проверка контейнеров

make ps

## Проверка ClickHouse

make clickhouse-client

Внутри ClickHouse:

SHOW DATABASES;

## Остановка

make down

## Полный сброс с удалением volumes

make reset
