#!/bin/bash
set -e

if ! command -v nc &> /dev/null; then
  echo "Installing netcat..."
  apt-get update && apt-get install -y netcat-openbsd || apk add --no-cache netcat-openbsd || true
fi

echo "Waiting for database to be ready..."
while ! nc -z "${POSTGRES_HOST:-db}" "${POSTGRES_PORT:-5432}"; do
  sleep 0.1
done
echo "Database is ready!"
