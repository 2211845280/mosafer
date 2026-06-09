#!/usr/bin/env bash
# Fresh local dev: wipe DB, run migrations, start stack — NO demo flight seed.
#
# Usage (from repo root):
#   ./scripts/fresh-start.sh
#   ./scripts/fresh-start.sh --skip-web
#   ./scripts/fresh-start.sh --flutter-device chrome

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SKIP_WEB=false
SKIP_FLUTTER=false
CLEAR_UPLOADS=false
FLUTTER_DEVICE="${FLUTTER_DEVICE:-chrome}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-web) SKIP_WEB=true ;;
    --skip-flutter) SKIP_FLUTTER=true ;;
    --clear-uploads) CLEAR_UPLOADS=true ;;
    --flutter-device)
      FLUTTER_DEVICE="${2:?device name required}"
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

echo ""
echo "=== Mosafer fresh start (empty trips, no demo seed) ==="
echo ""

echo "[1/4] Stopping Docker and removing database volumes..."
docker compose down -v

if [[ "$CLEAR_UPLOADS" == true ]]; then
  echo "[1b] Clearing local upload artifacts..."
  rm -f uploads/ticket_qr/* uploads/ticket_attachments/* uploads/passport_images/* 2>/dev/null || true
fi

echo "[2/4] Building and starting API + DB + Redis..."
docker compose up -d --build

echo "[3/4] Waiting for API health..."
for _ in $(seq 1 90); do
  if curl -fsS "http://localhost:8001/api/v1/health" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
curl -fsS "http://localhost:8001/api/v1/health" >/dev/null

echo ""
echo "Database is fresh. Demo Istanbul trips were NOT seeded."
echo "  API:  http://localhost:8001/docs"
echo "  Web:  http://localhost:3000/en"
echo "  Flutter: empty My Trips until you log in with the same web account."
echo ""
echo "Do NOT run scripts/seed_istanbul_review.py if you want zero preloaded flights."
echo ""

if [[ "$SKIP_WEB" != true ]]; then
  echo "[4a] Starting Next.js web app..."
  (
    cd web
    [[ -d node_modules ]] || npm install
    npm run dev
  ) &
fi

if [[ "$SKIP_FLUTTER" != true ]]; then
  echo "[4b] Launching Flutter ($FLUTTER_DEVICE)..."
  cd Flutter/app
  flutter pub get
  flutter run -d "$FLUTTER_DEVICE" --dart-define=API_BASE_URL=http://localhost:8001/api/v1
fi
