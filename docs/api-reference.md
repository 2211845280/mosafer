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
