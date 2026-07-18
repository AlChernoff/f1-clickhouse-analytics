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
