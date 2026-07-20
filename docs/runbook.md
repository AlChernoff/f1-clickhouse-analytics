# Runbook

## Start services

make up

## Stop services

make down

## Recreate local demo environment

Warning: removes local Docker volumes.

make demo-reset

## Check CSV files

make check-data

## Load data

make load-static
make replay-pit-stops
make replay-lap-times
make replay-results
make replay-qualifying

## Run transformations

make dbt-run
make dbt-test

## Monitoring

Grafana:

http://localhost:3000

Default local credentials:

admin / admin

Dashboard:

F1 Analytics → F1 Loader Monitoring

## BI dashboard

Superset:

http://localhost:8088

Default local credentials:

admin / admin

Dashboard:

F1 Analytics Dashboard

## Smoke test

make smoke-test

## Full demo

make demo
