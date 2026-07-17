FROM python:3.11-slim

WORKDIR /dbt

COPY --from=ghcr.io/astral-sh/uv:0.5.4 /uv /uvx /bin/

COPY dbt/pyproject.toml /dbt/pyproject.toml

RUN uv sync --no-dev

COPY dbt/ /dbt/

CMD ["uv", "run", "dbt", "--version"]
