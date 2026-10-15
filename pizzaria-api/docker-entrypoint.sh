#!/bin/sh
set -eu

alembic upgrade head

if [ "${IMPORT_CATALOG_ON_STARTUP:-false}" = "true" ]; then
  python scripts/import_catalog.py catalogo-real.json
fi

if [ "${IMPORT_PRODUCT_IMAGES_ON_STARTUP:-false}" = "true" ]; then
  python scripts/import_product_images.py \
    catalog-images-manifest.json \
    --assets-dir assets/catalog-images
fi

exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
