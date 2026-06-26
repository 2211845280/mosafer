# API Reference

## Base URLs

- `v1`: `/api/v1`
- `v2`: `/api/v2` (currently includes health scaffold endpoint)

## Authentication

Protected endpoints require JWT bearer token:

1. `POST /api/v1/auth/login`
2. Use `access_token` in `Authorization: Bearer <token>`

---

## Auth

### Register

- `POST /api/v1/auth/register`
- Request:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "StrongPass123!"
}
```
- Success `200`:
```json
{
  "message": "Registration successful",
  "user_id": 1,
  "email": "john@example.com"
}
```
- Common errors: `400` duplicate email, `422` invalid payload.

### Login

- `POST /api/v1/auth/login`
- Request:
```json
{
  "email": "john@example.com",
  "password": "StrongPass123!"
}
```
- Success `200`: includes `access_token` and token metadata.
- Common errors: `401` invalid credentials.

---

## Booking

### Create Reservation

- `POST /api/v1/reservations`
- Requires permission: `bookings.create`
- Request:
```json
{
  "provider_flight_id": "mock_f_123",
  "origin_iata": "CAI",
  "destination_iata": "DXB",
  "carrier_code": "MS",
  "flight_number": "123",
  "departure_at": "2026-08-01T10:00:00Z",
  "arrival_at": "2026-08-01T13:00:00Z",
  "base_price": "120.00",
  "currency": "USD",
  "seat": "12A",
  "total_price": "140.00"
}
```
- Success `200`: reservation object with embedded flight details.
- Common errors: `400` invalid seat format, `409` seat already taken.

---

## Tickets

### Scan Ticket QR

- `POST /api/v1/tickets/scan`
- Requires permission: `tickets.view`
- Request:
```json
{
  "qr_payload": "ABCD1234"
}
```
- Success `200`: ticket + reservation + flight summary.
- Common errors: `400` malformed QR payload, `404` ticket not found.

### Claim Ticket QR

<div dir="rtl">

| الحقل | التفاصيل |
| --- | --- |
| طريقة الطلب | `POST` |
| مسار الطلب | `/api/v1/tickets/claim` |
| رأس الطلب | `Authorization: Bearer <access_token>` و `Content-Type: application/json` |
| جسم الطلب | `{"ticket_number": "MS-123456-02"}` |
| النتيجة المتوقعة | ربط التذكرة أو تذكرة المسافر بالحساب الحالي بشكل دائم عبر `assigned_to_user_id`، مع بقاء `ordered_by_user_id` لصاحب الحجز الأصلي. |
| شكل الرد JSON | انظر المثال أدناه. |

</div>

```json
{
  "claimed": true,
  "ticket_number": "MS-123456-02",
  "reservation_id": 10,
  "assigned_to_user_id": 25,
  "scope": "passenger",
  "message": "Ticket assigned to this account",
  "flight": {
    "carrier_code": "MS",
    "flight_number": "123",
    "origin_iata": "CAI",
    "destination_iata": "DXB",
    "departure_at": "2026-08-01T10:00:00Z",
    "arrival_at": "2026-08-01T13:00:00Z",
    "seat": "12B"
  }
}
```

- Common errors: `400` missing ticket number, `404` ticket not found, `409` ticket already assigned to another account.

### Scan Ticket Image (Upload or Camera Capture)

- `POST /api/v1/tickets/scan-image`
- Requires permission: `tickets.view`
- Request: `multipart/form-data` with file field name `file`
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`
- Decision values in success `200` response:
  - `invalid_ticket`: image is not a valid ticket, cannot detect ticket number, ticket not found, or ticket is not in `valid` status
  - `expired_ticket`: ticket exists and is valid, but `now > departure_at + TICKET_EXPIRY_GRACE_MINUTES` (default 30)
  - `valid_ticket`: ticket exists, status is `valid`, and not expired
- Success `200` (example):
```json
{
  "decision": "valid_ticket",
  "warnings": [],
  "normalized_ticket_number": "TN1234ABCD",
  "extracted_fields": {
    "ticket_number": "TN1234ABCD",
    "passenger_name": "John Doe",
    "carrier_code": "MS",
    "flight_number": "123",
    "origin_iata": "CAI",
    "destination_iata": "DXB",
    "departure_at": "2026-08-01T10:00:00Z",
    "arrival_at": "2026-08-01T13:00:00Z",
    "seat": "12A",
    "ticket_status_hint": "valid"
  },
  "field_confidence": {
    "ticket_number": 0.98,
    "departure_at": 0.9
  },
  "raw_text": "MS 123 CAI DXB ...",
  "db_match": {
    "ticket_number": "TN1234ABCD",
    "ticket_status": "valid",
    "reservation_id": 10,
    "reservation_status": "booked",
    "flight": {
      "carrier_code": "MS",
      "flight_number": "123",
      "origin_iata": "CAI",
      "destination_iata": "DXB",
      "departure_at": "2026-08-01T10:00:00Z",
      "arrival_at": "2026-08-01T13:00:00Z",
      "seat": "12A"
    },
    "issued_at": "2026-07-31T10:00:00Z"
  }
}
```
- Common errors: `400` unsupported image type, oversized upload, invalid file content signature.

---

## Notifications

### Send Saved Push Notification

<div dir="rtl">

| الحقل | التفاصيل |
| --- | --- |
| طريقة الطلب | `POST` |
| مسار الطلب | `/api/v1/notifications/send` |
| رأس الطلب | `Authorization: Bearer <access_token>` و `Content-Type: application/json` |
| جسم الطلب | `title`, `body`, `type`, و اختيارياً `target_user_id`, `data` |
| النتيجة المتوقعة | يحفظ الإشعار في جدول `notifications` حتى يظهر في قائمة الإشعارات، ثم يرسله Push عبر Firebase للجهاز المسجل. |
| ملاحظة الصلاحيات | إذا لم ترسل `target_user_id` يرسل الإشعار لحسابك الحالي. إرسال إشعار لمستخدم آخر يتطلب صلاحية أدمن. |

</div>

```json
{
  "title": "تذكير بالرحلة",
  "body": "تبقى 24 ساعة على رحلتك.",
  "type": "manual",
  "target_user_id": 25,
  "data": {
    "reservation_id": "10"
  }
}
```

Success `200`:

```json
{
  "notification": {
    "id": 120,
    "user_id": 25,
    "type": "manual",
    "title": "تذكير بالرحلة",
    "body": "تبقى 24 ساعة على رحلتك.",
    "read": false,
    "created_at": "2026-08-01T10:00:00Z"
  },
  "push_requested": true,
  "push_tokens": 1,
  "push_successes": 1
}
```

---

## Payments

### Create Payment Session

- `POST /api/v1/payments/create-session`
- Request:
```json
{
  "reservation_id": 10
}
```
- Success `201`:
```json
{
  "payment_id": 20,
  "session_id": "sess_xxx",
  "checkout_url": "https://mock.pay/checkout/...",
  "status": "pending"
}
```

### Webhook

- `POST /api/v1/payments/webhook`
- Request:
```json
{
  "provider_payment_id": "mock_pay_123",
  "status": "completed",
  "signature": "optional-signature"
}
```
- Success `200`: `{"status":"ok"}`
- Common errors: `400` invalid signature, `404` payment not found.

### Refund

- `POST /api/v1/payments/{payment_id}/refund`
- Success `200`: refund confirmation payload.
- Common errors: `409` payment not completed.

---

## Health and Observability

- `GET /api/v1/health` deep health status (`db`, `redis`, `external`)
- `GET /api/v2/health` v2 health probe
- `GET /metrics` Prometheus-formatted metrics
