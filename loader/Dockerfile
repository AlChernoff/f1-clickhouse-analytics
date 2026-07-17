FROM python:3.11-slim

WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:0.5.4 /uv /uvx /bin/

COPY loader/pyproject.toml /app/pyproject.toml

RUN uv sync --no-dev

COPY loader/ /app/

CMD ["uv", "run", "python", "main.py"]
