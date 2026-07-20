# Local deployment

Run commands from the project directory.

## First start

```bash
cp .env.example .env
make up
make ps
```

`make up` waits for ClickHouse and Superset readiness. Build images explicitly after Dockerfile or dependency changes:

```bash
make build
make build SERVICE=loader
```

## Stop or recreate

```bash
make down
make reset  # removes local Docker volumes
```

Use `make clickhouse` to open an interactive ClickHouse client.
