FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN addgroup --system app && adduser --system --ingroup app app

COPY pyproject.toml README.md ./
COPY app ./app
COPY migrations ./migrations
COPY scripts ./scripts
COPY catalogo-real.json ./catalogo-real.json
COPY catalog.real.example.json ./catalog.real.example.json
COPY alembic.ini ./
COPY docker-entrypoint.sh ./

RUN pip install --no-cache-dir . && mkdir -p /app/uploads && chmod +x docker-entrypoint.sh && chown -R app:app /app

USER app
EXPOSE 8000

ENTRYPOINT ["/app/docker-entrypoint.sh"]
