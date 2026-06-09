#!/bin/bash
set -e

/app/docker/entrypoint-wait-db.sh

echo "Running database migrations (single-run job)..."
uv run python -m app.db.migrate
echo "Migrations complete."
