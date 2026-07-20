.PHONY: up down restart ps logs reset clickhouse-client loader dbt-version superset-init

up:
	docker compose up -d clickhouse grafana superset

down:
	docker compose down

restart:
	docker compose down
	docker compose up -d clickhouse grafana superset

ps:
	docker compose ps

logs:
	docker compose logs -f

reset:
	docker compose down -v
	docker compose up -d clickhouse grafana superset

clickhouse-client:
	docker compose exec clickhouse clickhouse-client

loader:
	docker compose run --rm loader uv run python main.py

dbt-version:
	docker compose run --rm dbt uv run dbt --version

load-static:
	docker compose run --rm loader uv run python load_static.py

replay-lap-times:
	docker compose run --rm loader uv run python replay_loader.py --table lap_times --batch-size 10000 --sleep-seconds 0.1

replay-pit-stops:
	docker compose run --rm loader uv run python replay_loader.py --table pit_stops --batch-size 1000 --sleep-seconds 0.1

replay-all:
	docker compose run --rm loader uv run python replay_loader.py --table all --batch-size 1000 --sleep-seconds 1
replay-results:
	docker compose run --rm loader uv run python replay_loader.py --table results --batch-size 10000 --sleep-seconds 0.1

replay-qualifying:
	docker compose run --rm loader uv run python replay_loader.py --table qualifying --batch-size 10000 --sleep-seconds 0.1

dbt-debug:
	docker compose run --rm dbt uv run dbt debug --profiles-dir .

dbt-run:
	docker compose run --rm dbt uv run dbt run --profiles-dir .

dbt-test:
	docker compose run --rm dbt uv run dbt test --profiles-dir .

dbt-build:
	docker compose run --rm dbt uv run dbt build --profiles-dir .

truncate-raw:
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE raw.drivers"
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE raw.constructors"
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE raw.circuits"
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE raw.races"
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE raw.results"
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE raw.lap_times"
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE raw.pit_stops"
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE raw.qualifying"

truncate-monitoring:
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE monitoring.load_batches"
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE monitoring.load_errors"
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE monitoring.pipeline_status"
	docker compose exec clickhouse clickhouse-client --query "TRUNCATE TABLE monitoring.loader_stats_1m"

demo-reset-data: truncate-raw truncate-monitoring

superset-build:
	docker compose build superset

superset-init:
	docker compose exec superset superset db upgrade
	docker compose exec superset superset fab create-admin \
		--username admin \
		--firstname Admin \
		--lastname User \
		--email admin@example.com \
		--password admin || true
	docker compose exec superset superset init

superset-logs:
	docker compose logs -f superset

superset-import:
	docker compose exec superset bash /app/project_superset/import_dashboard.sh

demo-reset:
	docker compose down -v
	docker compose up -d clickhouse grafana superset

demo-load:
	$(MAKE) check-data
	docker compose run --rm loader uv run python load_static.py
	docker compose run --rm loader uv run python replay_loader.py --table pit_stops --batch-size 1000 --sleep-seconds 0.1
	docker compose run --rm loader uv run python replay_loader.py --table lap_times --batch-size 10000 --sleep-seconds 0.1
	docker compose run --rm loader uv run python replay_loader.py --table results --batch-size 10000 --sleep-seconds 0.1
	docker compose run --rm loader uv run python replay_loader.py --table qualifying --batch-size 10000 --sleep-seconds 0.1

demo-transform:
	docker compose run --rm dbt uv run dbt run --profiles-dir .
	docker compose run --rm dbt uv run dbt test --profiles-dir .

demo-check:
	docker compose exec clickhouse clickhouse-client --query "SELECT 'raw.drivers' AS table_name, count() AS rows_count FROM raw.drivers UNION ALL SELECT 'raw.races', count() FROM raw.races UNION ALL SELECT 'raw.results', count() FROM raw.results UNION ALL SELECT 'raw.lap_times', count() FROM raw.lap_times UNION ALL SELECT 'raw.pit_stops', count() FROM raw.pit_stops UNION ALL SELECT 'raw.qualifying', count() FROM raw.qualifying"
	docker compose exec clickhouse clickhouse-client --query "SELECT driver_name, total_points, wins, podiums FROM marts.mart_driver_performance ORDER BY total_points DESC LIMIT 10"
	docker compose exec clickhouse clickhouse-client --query "SELECT source_name, target_table, rows_loaded, status FROM monitoring.load_batches ORDER BY started_at DESC LIMIT 10"

demo:
	$(MAKE) demo-reset
	$(MAKE) demo-load
	$(MAKE) demo-transform
	$(MAKE) superset-init
	$(MAKE) superset-import
	$(MAKE) demo-check

check-data:
	test -f data/raw/drivers.csv
	test -f data/raw/constructors.csv
	test -f data/raw/circuits.csv
	test -f data/raw/races.csv
	test -f data/raw/results.csv
	test -f data/raw/lap_times.csv
	test -f data/raw/pit_stops.csv
	test -f data/raw/qualifying.csv
	@echo "All required CSV files are present."

smoke-test:
	docker compose ps
	docker compose exec clickhouse clickhouse-client --query "SELECT 1"
	docker compose run --rm loader uv run python main.py
	docker compose run --rm dbt uv run dbt debug --profiles-dir .

demo-show:
	bash scripts/demo_show.sh
