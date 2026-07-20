# F1 ClickHouse Analytics

Local analytics platform for Formula 1 data: Python loads CSV files into ClickHouse, dbt builds analytical views, Grafana monitors ingestion, and Superset presents dashboards.

## Quick start

Run commands from this directory.

```bash
cp .env.example .env
make check-data
make demo
```

`make demo` removes local Docker volumes, loads the data, builds dbt models, and initializes the Superset dashboard.

Afterward, inspect the result with:

```bash
make demo-show
```

Useful URLs:

- Grafana: <http://localhost:3000>
- Superset: <http://localhost:8088>

Default local credentials are defined in `.env` (`admin` / `admin` in `.env.example`).

## Daily commands

```bash
make up                    # start services
make load                  # load dimensions and replay event data
make transform             # run dbt build
make replay TABLE=results  # replay one event table
make clean-data            # delete loaded data, retain Docker volumes
make test                  # run loader unit tests
make ci                    # run local preflight checks
```

Run `make help` to see the complete public command list. Detailed operational guidance is in [docs/runbook.md](docs/runbook.md); the presentation flow is in [docs/demo_script.md](docs/demo_script.md).

## Architecture

```text
F1 CSV Dataset
      ↓
Python Replay Loader
      ↓
ClickHouse RAW Layer
      ↓
dbt Transformations
      ↓
ClickHouse DWH and MARTS
      ↓
Grafana Monitoring and Superset BI
```
