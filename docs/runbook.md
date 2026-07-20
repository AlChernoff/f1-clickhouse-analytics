# Runbook

## Standard workflow

```bash
make up
make check-data
make load
make transform
make demo-show
```

To replay only one event source, use:

```bash
make replay TABLE=lap_times
```

Available values: `lap_times`, `pit_stops`, `results`, `qualifying`, and `all`.

## Diagnostics

```bash
make ps
make logs SERVICE=clickhouse
make smoke-test
make ci
make clickhouse
```

## Data and environment recovery

```bash
make clean-data  # removes raw, monitoring, DWH and mart data; retains volumes
make reset       # removes all local project volumes and starts a clean stack
make demo        # reset, load, transform, initialize BI, and print checks
```

`make reset` and `make demo` delete local Docker volumes.

## Dashboards

- Grafana: <http://localhost:3000>, dashboard **F1 Analytics → F1 Loader Monitoring**.
- Superset: <http://localhost:8088>, dashboard **F1 Analytics Dashboard**.

Credentials are defined in `.env`; `.env.example` provides local defaults.
