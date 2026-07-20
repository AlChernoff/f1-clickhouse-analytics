SHELL := /bin/sh
.DEFAULT_GOAL := help

COMPOSE ?= docker compose
WAIT_ATTEMPTS ?= 30
WAIT_SECONDS ?= 2
REPLAY_BATCH_SIZE ?= 10000
REPLAY_SLEEP_SECONDS ?= 0.1

DATA_FILES := drivers.csv constructors.csv circuits.csv races.csv results.csv lap_times.csv pit_stops.csv qualifying.csv

.PHONY: help check-env up down restart ps logs reset clickhouse-client \
	loader dbt-version load-static replay-lap-times replay-pit-stops replay-results \
	replay-qualifying replay-all dbt-debug dbt-run dbt-test dbt-build \
	truncate-raw truncate-monitoring drop-dwh drop-marts demo-reset-data build \
	loader-build dbt-image-build superset-build superset-init \
	superset-logs superset-import demo-reset demo-load demo-transform demo-check demo \
	check-data test smoke-test ci demo-show wait-superset

.NOTPARALLEL: demo

define wait_for_superset
	@attempt=1; \
	until $(COMPOSE) exec -T superset python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8088/health', timeout=3).read()" >/dev/null 2>&1; do \
		if [ $$attempt -ge $(WAIT_ATTEMPTS) ]; then \
			echo "Superset did not become ready after $(WAIT_ATTEMPTS) attempts." >&2; \
			$(COMPOSE) logs --tail=100 superset >&2 || true; \
			exit 1; \
		fi; \
		echo "Waiting for Superset ($$attempt/$(WAIT_ATTEMPTS))..."; \
		sleep $(WAIT_SECONDS); \
		attempt=$$((attempt + 1)); \
	done
endef

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "%-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-env: ## Validate local Docker Compose configuration
	@test -f .env || { echo "Missing .env. Create it from .env.example before starting the stack." >&2; exit 1; }
	@$(COMPOSE) config --quiet

up: check-env ## Start the application stack and wait for readiness
	$(COMPOSE) up -d --wait clickhouse grafana superset
	$(wait_for_superset)

down: ## Stop the application stack
	$(COMPOSE) down

restart: ## Restart the application stack without deleting volumes
	$(COMPOSE) down
	$(COMPOSE) up -d --wait clickhouse grafana superset
	$(wait_for_superset)

ps: ## Show application containers
	$(COMPOSE) ps

logs: ## Follow logs for all services
	$(COMPOSE) logs -f

reset: check-env ## Remove volumes and recreate the application stack
	@echo "WARNING: this removes all local Docker volumes for this project."
	$(COMPOSE) down -v
	$(COMPOSE) up -d --wait clickhouse grafana superset
	$(wait_for_superset)

clickhouse-client: ## Open an interactive ClickHouse client
	$(COMPOSE) exec clickhouse clickhouse-client

loader: ## Check that the loader container can connect to ClickHouse
	$(COMPOSE) run --rm loader uv run python -c "from src.clickhouse_client import get_client; print(get_client().command('SELECT 1'))"

dbt-version: ## Show the installed dbt version
	$(COMPOSE) run --rm dbt uv run dbt --version

load-static: check-data ## Load static CSV dimensions
	$(COMPOSE) run --rm loader uv run python load_static.py

replay-lap-times: check-data ## Replay lap times
	$(COMPOSE) run --rm loader uv run python replay_loader.py --table lap_times --batch-size $(REPLAY_BATCH_SIZE) --sleep-seconds $(REPLAY_SLEEP_SECONDS)

replay-pit-stops: check-data ## Replay pit stops
	$(COMPOSE) run --rm loader uv run python replay_loader.py --table pit_stops --batch-size $(REPLAY_BATCH_SIZE) --sleep-seconds $(REPLAY_SLEEP_SECONDS)

replay-results: check-data ## Replay race results
	$(COMPOSE) run --rm loader uv run python replay_loader.py --table results --batch-size $(REPLAY_BATCH_SIZE) --sleep-seconds $(REPLAY_SLEEP_SECONDS)

replay-qualifying: check-data ## Replay qualifying results
	$(COMPOSE) run --rm loader uv run python replay_loader.py --table qualifying --batch-size $(REPLAY_BATCH_SIZE) --sleep-seconds $(REPLAY_SLEEP_SECONDS)

replay-all: check-data ## Replay all event tables
	$(COMPOSE) run --rm loader uv run python replay_loader.py --table all --batch-size $(REPLAY_BATCH_SIZE) --sleep-seconds $(REPLAY_SLEEP_SECONDS)

dbt-debug: ## Validate dbt connectivity
	$(COMPOSE) run --rm dbt uv run dbt debug --profiles-dir .

dbt-run: ## Run dbt models
	$(COMPOSE) run --rm dbt uv run dbt run --profiles-dir .

dbt-test: ## Run dbt tests
	$(COMPOSE) run --rm dbt uv run dbt test --profiles-dir .

dbt-build: ## Run dbt models and tests
	$(COMPOSE) run --rm dbt uv run dbt build --profiles-dir .

truncate-raw: ## Remove all data from raw tables
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE raw.drivers"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE raw.constructors"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE raw.circuits"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE raw.races"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE raw.results"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE raw.lap_times"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE raw.pit_stops"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE raw.qualifying"

truncate-monitoring: ## Remove loader monitoring history
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE monitoring.load_batches"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE monitoring.load_errors"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE monitoring.pipeline_status"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "TRUNCATE TABLE monitoring.loader_stats_1m"

drop-dwh: ## Drop dbt views in the DWH layer
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.stg_circuits"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.stg_constructors"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.stg_drivers"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.stg_lap_times"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.stg_pit_stops"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.stg_qualifying"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.stg_races"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.stg_results"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.dim_constructors"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.dim_drivers"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.dim_races"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.fact_lap_times"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.fact_pit_stops"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS dwh.fact_race_results"

drop-marts: ## Drop dbt views in the marts layer
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS marts.mart_constructor_performance"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS marts.mart_driver_performance"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS marts.mart_lap_time_analysis"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS marts.mart_pit_stop_efficiency"
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "DROP VIEW IF EXISTS marts.mart_season_summary"

demo-reset-data: truncate-raw truncate-monitoring drop-dwh drop-marts ## Remove all loaded and transformed demo data

build: ## Build all local images
	$(COMPOSE) build

loader-build: ## Build the loader image
	$(COMPOSE) build loader

dbt-image-build: ## Build the dbt image
	$(COMPOSE) build dbt

superset-build: ## Build the Superset image
	$(COMPOSE) build superset

wait-superset: ## Wait until the Superset HTTP health endpoint responds
	$(wait_for_superset)

superset-init: wait-superset ## Initialize Superset metadata and admin user
	$(COMPOSE) exec -T superset superset db upgrade
	@output="$$($(COMPOSE) exec -T superset sh -ec 'superset fab create-admin --username "$$SUPERSET_ADMIN_USER" --firstname Admin --lastname User --email "$$SUPERSET_ADMIN_EMAIL" --password "$$SUPERSET_ADMIN_PASSWORD"' 2>&1)" || { \
		status=$$?; echo "$$output"; echo "$$output" | grep -qi "already exists" || exit $$status; \
	}
	$(COMPOSE) exec -T superset superset init

superset-logs: ## Follow Superset logs
	$(COMPOSE) logs -f superset

superset-import: wait-superset ## Import the Superset dashboard
	$(COMPOSE) exec -T superset bash /app/project_superset/import_dashboard.sh

demo-reset: reset ## Recreate a clean demo environment

demo-load: load-static replay-pit-stops replay-lap-times replay-results replay-qualifying ## Load all demo data

demo-transform: dbt-build ## Build and test analytical models

demo-check: check-env ## Print demo data and monitoring checks
	@set -a; . ./.env; set +a; bash scripts/demo_show.sh

demo: demo-reset demo-load demo-transform superset-init superset-import demo-check ## Run the complete demo from scratch

check-data: ## Verify that all required CSV files exist and are non-empty
	@for file in $(DATA_FILES); do \
		path="data/raw/$$file"; \
		if [ ! -s "$$path" ]; then \
			echo "Missing or empty required CSV: $$path" >&2; \
			exit 1; \
		fi; \
		if ! head -n 1 "$$path" | grep -q ','; then \
			echo "CSV header is invalid: $$path" >&2; \
			exit 1; \
		fi; \
	done
	@echo "All required CSV files are present and non-empty."

smoke-test: check-env ## Verify ClickHouse, loader connectivity, and dbt connectivity
	$(COMPOSE) ps
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "SELECT 1"
	$(COMPOSE) run --rm loader uv run python -c "from src.clickhouse_client import get_client; print(get_client().command('SELECT 1'))"
	$(COMPOSE) run --rm dbt uv run dbt debug --profiles-dir .

test: ## Run loader unit tests
	$(COMPOSE) run --rm --no-deps loader uv run python -m unittest discover -s tests

ci: check-data test smoke-test ## Run local CI preflight against a running stack
	$(COMPOSE) run --rm loader uv run python -m compileall -q .

demo-show: demo-check ## Show the current demo state
