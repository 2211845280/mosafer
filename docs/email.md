# Email (SMTP)

## Development — Mailpit

With Docker Compose, Mailpit starts automatically:

- SMTP: `localhost:1025` (from host) or `mailpit:1025` (from API container)
- Web UI: [http://localhost:8025](http://localhost:8025)

All transactional emails (verification, password reset, booking confirmations) appear in the Mailpit inbox.

## Production — Gmail

1. Enable 2-Step Verification on the Google account.
2. Create an [App Password](https://myaccount.google.com/apppasswords).
3. Set in `.env`:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_START_TLS=true
SMTP_USER=you@gmail.com
SMTP_PASSWORD=your-16-char-app-password
SMTP_FROM=you@gmail.com
```

## Password reset flow

1. User requests reset via Flutter, web, or `POST /api/v1/auth/forgot-password`.
2. Email contains a link to `{API_PUBLIC_URL}/api/v1/auth/reset-password?token=...`.
3. GET redirects to `{WEB_APP_URL}/en/reset-password?token=...`.
4. User submits a new password via web or Flutter (`POST /api/v1/auth/reset-password`).
