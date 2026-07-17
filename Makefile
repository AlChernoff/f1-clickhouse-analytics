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

superset-init:
	docker compose exec superset superset db upgrade
	docker compose exec superset superset fab create-admin \
		--username admin \
		--firstname Admin \
		--lastname User \
		--email admin@example.com \
		--password admin || true
	docker compose exec superset superset init
