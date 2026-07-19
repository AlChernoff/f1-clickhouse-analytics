FROM python:3.11-slim

WORKDIR /dbt

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.5.4 /uv /uvx /bin/

COPY dbt/pyproject.toml /dbt/pyproject.toml

RUN uv sync --no-dev

COPY dbt/ /dbt/

CMD ["uv", "run", "dbt", "--version"]
