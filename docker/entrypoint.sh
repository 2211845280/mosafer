#!/bin/bash
set -e

# Wait for PostgreSQL only. Migrations run once via the `migrate` compose service.
/app/docker/entrypoint-wait-db.sh

exec "$@"
