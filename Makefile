SHELL := /bin/sh
.DEFAULT_GOAL := help

COMPOSE ?= docker compose
SERVICE ?=
TABLE ?= all
REPLAY_BATCH_SIZE ?= 10000
REPLAY_SLEEP_SECONDS ?= 0.1
WAIT_ATTEMPTS ?= 30
WAIT_SECONDS ?= 2

DATA_FILES := drivers.csv constructors.csv circuits.csv races.csv results.csv lap_times.csv pit_stops.csv qualifying.csv

.PHONY: help up down ps logs build reset clean-data check-data load replay transform \
	bi-init clickhouse test lint smoke-test ci demo demo-show \
	_wait-superset _load-static _superset-init _superset-import

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
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "%-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-env:
	@test -f .env || { echo "Missing .env. Create it from .env.example." >&2; exit 1; }
	@$(COMPOSE) config --quiet

up: check-env ## Start the application stack
	$(COMPOSE) up -d --wait clickhouse grafana superset
	$(wait_for_superset)

down: ## Stop the application stack
	$(COMPOSE) down

ps: ## Show service status
	$(COMPOSE) ps

logs: ## Follow logs; use SERVICE=name to filter
	$(COMPOSE) logs -f $(SERVICE)

build: check-env ## Build images; use SERVICE=name to build one image
	$(COMPOSE) build $(SERVICE)

reset: check-env ## Delete local volumes and recreate the stack
	@echo "WARNING: this removes all local Docker volumes for this project."
	$(COMPOSE) down -v
	$(COMPOSE) up -d --wait clickhouse grafana superset
	$(wait_for_superset)

check-data: ## Verify required CSV files are present and non-empty
	@for file in $(DATA_FILES); do \
		path="data/raw/$$file"; \
		if [ ! -s "$$path" ]; then \
			echo "Missing or empty required CSV: $$path" >&2; \
			exit 1; \
		fi; \
	done
	@echo "All required CSV files are present and non-empty."

load: check-data ## Load static data and replay all event tables
	$(MAKE) --no-print-directory _load-static
	$(MAKE) --no-print-directory replay TABLE=all

replay: check-data ## Replay events; use TABLE=lap_times|pit_stops|results|qualifying|all
	$(COMPOSE) run --rm loader uv run python replay_loader.py --table $(TABLE) --batch-size $(REPLAY_BATCH_SIZE) --sleep-seconds $(REPLAY_SLEEP_SECONDS)

transform: ## Build dbt models and run dbt tests
	$(COMPOSE) run --rm dbt uv run dbt build --profiles-dir .

bi-init: _superset-init _superset-import ## Initialize Superset and import the dashboard

clickhouse: ## Open an interactive ClickHouse client
	$(COMPOSE) exec clickhouse clickhouse-client

test: ## Run loader unit tests
	$(COMPOSE) run --rm --no-deps loader uv run python -m unittest discover -s tests

lint: ## Run Python static checks
	$(COMPOSE) run --rm --no-deps loader uv run ruff check .

smoke-test: check-env ## Verify ClickHouse, loader, and dbt connectivity
	$(COMPOSE) ps
	$(COMPOSE) exec -T clickhouse clickhouse-client --query "SELECT 1"
	$(COMPOSE) run --rm loader uv run python -c "from src.clickhouse_client import get_client; print(get_client().command('SELECT 1'))"
	$(COMPOSE) run --rm dbt uv run dbt debug --profiles-dir .

ci: check-data lint test smoke-test ## Run local CI preflight against a running stack
	$(COMPOSE) run --rm loader uv run python -m compileall -q .

demo: reset load transform bi-init demo-show ## Recreate and demonstrate the complete pipeline

demo-show: check-env ## Show loaded data, marts, and monitoring
	@set -a; . ./.env; set +a; bash scripts/demo_show.sh

clean-data: ## Delete loaded data but keep Docker volumes
	$(COMPOSE) exec -T clickhouse clickhouse-client --multiquery < clickhouse/maintenance/clean_data.sql

_load-static:
	$(COMPOSE) run --rm loader uv run python load_static.py

_wait-superset:
	$(wait_for_superset)

_superset-init: _wait-superset
	$(COMPOSE) exec -T superset superset db upgrade
	@output="$$($(COMPOSE) exec -T superset sh -ec 'superset fab create-admin --username "$$SUPERSET_ADMIN_USER" --firstname Admin --lastname User --email "$$SUPERSET_ADMIN_EMAIL" --password "$$SUPERSET_ADMIN_PASSWORD"' 2>&1)" || { \
		status=$$?; echo "$$output"; echo "$$output" | grep -qi "already exists" || exit $$status; \
	}
	$(COMPOSE) exec -T superset superset init

_superset-import: _wait-superset
	$(COMPOSE) exec -T superset bash /app/project_superset/import_dashboard.sh
