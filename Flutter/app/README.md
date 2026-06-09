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
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001/api/v1
```

Use `10.0.2.2` for the Android emulator. For a physical phone, replace it with your computer LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:8001/api/v1
```

For web or desktop on the same machine:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8001/api/v1
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
