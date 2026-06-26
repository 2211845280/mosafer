# Mosafer Flutter App

Mobile client for the Mosafer FastAPI backend. The app uses the dark Mosafer visual identity from the UI plan and connects to `/api/v1` for authentication, profile, tickets, reservations, trip todos, departure planning, and airport mode.

## Requirements

- Flutter SDK 3.9+
- Android Studio or Xcode for device/emulator builds
- Backend running from the repository root on port `8001`
- Windows only: enable Developer Mode if you build desktop or use Flutter plugins locally

## Run The Backend

From the repository root:

```bash
uv run uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
```

The app expects the API base URL to include `/api/v1`.

## Run The Flutter App

From `Flutter/app`:

```bash
flutter pub get
```

| Target | Command |
|--------|---------|
| **Physical Android phone** | `flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:8001/api/v1` |
| **Android emulator** | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001/api/v1` |
| **Chrome (UI testing)** | `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8001/api/v1` |

Replace `YOUR_COMPUTER_IP` with your PC LAN address from `ipconfig` (e.g. `192.168.1.106`). The phone and PC must be on the same Wi‑Fi.

- **Physical phone / emulator:** Firebase push notifications are enabled.
- **Chrome:** Firebase is skipped (web is not configured); login, booking, and in-app notifications via the API still work. Use `localhost` because the browser runs on the same machine as the API.

Example physical device:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.106:8001/api/v1
```

Example Chrome:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8001/api/v1
```

## Booking Website (Explore tab)

The **OPEN BOOKING WEBSITE** button opens the Next.js booking site in the device browser. Start the web app first (`npm run dev` from the repository `web/` folder). The app derives the web URL from `API_BASE_URL` (same host, port `3000`), e.g. `http://192.168.1.106:8001/api/v1` → `http://192.168.1.106:3000/en`.

For production, pass an explicit base URL:

```bash
flutter run --dart-define=WEB_BASE_URL=https://yourdomain.com
```

## Developer Test Flow

1. Register a new account or login with an existing backend user.
2. Open Profile, edit personal details, and optionally upload a profile image.
3. Open My Trips to load `/reservations/me`.
4. Tap `+` to scan a ticket. In dev mode, paste the raw QR payload from a backend ticket into the sheet.
5. After validation, the app opens the active trip dashboard.
6. Use Plan Departure to request departure timing and location-based stage detection.
7. Use Trip Todos to load backend todos for the active reservation.
8. Use Airport Experience once the location check reports the user is at the airport.

## Test Departure & Trip Todo Notifications (real device)

From the repository root, with `docker compose up -d` (API + worker + Redis + DB):

1. Log into the Flutter app on your phone with the target account (e.g. `abdo@gmail.com`).
2. Run (inside Docker so DB/Redis hostnames resolve):

**Departure reminders** (`flight_departure_6h`, `home_departure_2h/30m/critical`):

```bash
docker compose exec api uv run python scripts/trigger_departure_notification_test.py --email abdo@gmail.com --type departure --tier all
```

**Trip todo reminders** (`trip_todo_14d` … `trip_todo_3h`):

```bash
docker compose exec api uv run python scripts/trigger_departure_notification_test.py --email abdo@gmail.com --type todo --tier 3d
```

Or on the host if `.env` uses `localhost` for Postgres/Redis:

```bash
uv run python scripts/trigger_departure_notification_test.py --email abdo@gmail.com --type departure --tier critical
```

3. Open the notifications screen in the app and pull to refresh after each tier.

The script adjusts the active IST trip timing to the current moment, clears Redis dedup keys, and runs the matching worker immediately (cron runs every 15 minutes in production).

Single departure tier: `--tier critical`, `30m`, `2h`, or `flight_6h`.

Single todo tier: `--tier 14d`, `7d`, `3d`, `1d`, `6h`, or `3h`.

Tap a notification to mark it read; swipe left to delete.

## Useful Commands

```bash
flutter analyze
flutter test
flutter clean
flutter pub get
```

## Notes

- Auth uses JWT access tokens and refresh tokens stored with `flutter_secure_storage`.
- Location permissions are requested at runtime for stage detection.
- Google Maps navigation opens externally through Google Maps URLs. This keeps the dev setup simple while still giving users real navigation.
- If Flutter plugin setup fails on Windows with a symlink message, enable Developer Mode from Windows Settings, then run `flutter pub get` again.
