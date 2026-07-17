# Deployment

## Requirements

- Docker
- Docker Compose
- make

## Start

cp .env.example .env
make up

## Check containers

make ps

## Check ClickHouse

make clickhouse-client

Inside ClickHouse:

SHOW DATABASES;

## Stop

make down

## Full reset with volume removal

make reset
