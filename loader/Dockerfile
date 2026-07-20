FROM python:3.11-slim

WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:0.5.4 /uv /uvx /bin/

COPY loader/pyproject.toml loader/uv.lock /app/

RUN uv sync --frozen --no-dev

COPY loader/ /app/

CMD ["uv", "run", "python", "replay_loader.py", "--help"]
