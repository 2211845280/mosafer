# Mosafer — Full Project Review & Roadmap

> **Date:** 2026-04-04
> **Scope:** Backend API for a mobile app + web app serving frequent travelers.
> **Stack:** FastAPI · PostgreSQL · SQLAlchemy (async) · Alembic · Docker · GitHub Actions

---

## Table of Contents

1. [Product Vision (Target State)](#1-product-vision-target-state)
2. [Current State Audit](#2-current-state-audit)
3. [Bugs & Issues to Fix Now](#3-bugs--issues-to-fix-now)
4. [Architecture Decisions Needed](#4-architecture-decisions-needed)
5. [Epic Roadmap (Ordered Tasks)](#5-epic-roadmap-ordered-tasks)
6. [External APIs Reference](#6-external-apis-reference)
7. [Non-Functional Requirements](#7-non-functional-requirements)

---

## 1. Product Vision (Target State)

The product is **Mosafer** — a smart travel companion backend that powers both a **mobile app** (scan/track tickets) and a **web app** (search/buy tickets). The full feature set:

| Feature Area | Description |
|---|---|
| **Ticket Purchase (Web)** | Search flights via **Mock Flight API**, buy tickets, generate QR codes |
| **Ticket Scan (App)** | Scan QR from web purchase → import full flight data into the mobile app |
| **AI Travel Agent** | Destination-aware packing lists (must-have → optional), warns about items unavailable at destination |
| **Smart Airport Timer** | Calculates when to leave based on: user location, airport location, transport mode (car/train/taxi), live traffic, weather |
| **Live Flight Tracker** | Shows counter, check-in desk, boarding gate, time remaining, suggests eat-near-gate or explore |
| **Flight Status API** | Real-time flight status (delays, gate changes, cancellations) pushed to user |
| **Airport Info API** | Airport maps, terminal info, amenities, lounges |

---

## 2. Current State Audit

### 2.1 What Exists and Works

| Layer | Status | Details |
|---|---|---|
| **Project scaffolding** | Done | FastAPI app, Docker (dev/staging/prod), docker-compose, CI/CD GitHub Actions |
| **Database** | Done | Async SQLAlchemy + asyncpg, Alembic migrations, connection pooling |
| **Auth** | Done | Registration, login (JWT + bearer), logout with token revocation (blacklist), password hashing (bcrypt/passlib) |
| **RBAC** | Done | Roles, Permissions, RolePermissions link table, `require_permission()` dependency, admin seed migration |
| **User management** | Done | Profile read/update, avatar upload, password change, admin CRUD (enable/disable/role change/delete) |
| **Airports** | Done | Full CRUD (create/list/get/update/delete), IATA code, city, country, timezone |
| **Flights** | Partial | Admin create/list; **public flight search targets Mock Flight API** (Epic 2). Retire any legacy flight-provider code during housekeeping. |
| **Reservations** | Done | Create booking (upserts flight, validates seat, issues ticket + QR), list user bookings, cancel booking |
| **Tickets** | Done | List/history (with filters), get by number, validate (QR scan flow: valid→used), download PDF, upload attachments, admin report |
| **QR System** | Done | QR PNG generation per ticket, QR content encoding, PDF embedding |
| **Testing** | Partial | Smoke tests (root, health), unit tests (seat validation, flight-offer normalization helpers). No integration tests for auth/booking flows |
| **CI Pipeline** | Done | Ruff lint + format, pytest with Postgres service, coverage upload, Docker build test |
| **CD Pipeline** | Scaffold | Builds and pushes to GHCR; deploy steps are placeholder `echo` commands |

### 2.2 What Does NOT Exist Yet

- OpenAI LLM integration with packing lists, destination tips, and trip timelines (Epic 5); trip todos and feedback loop implemented
- Mock geolocation, route calculation, and traffic/weather services integrated (Epic 4); replace with real Google Maps + OpenWeatherMap when ready
- Mock flight status service integrated (Epic 3); SSE live updates available; replace with real provider when ready
- Notification dispatcher with FCM push + Resend email + in-app DB fan-out (Epic 8); wired into flight status, departure alerts, and payments
- Mock payment integration (Epic 7); create-session, webhook, status, refund endpoints ready; swap mock service for Stripe/PayMob when needed
- Mock Flight API integrated (Epic 2); replace with real provider when ready
- No in-airport experience dashboard (Epic 6 — skipped pending API access)
- No webapp-to-app QR bridge (the current QR is ticket-number-only, not a deep link with full flight data)
- No production hardening (Epic 9)

---

## 3. Bugs & Issues to Fix Now

These should be fixed before building new features.

### 3.1 Critical

| # | Issue | Location | What to Do |
|---|---|---|---|
| B1 | **Duplicate security module** — `app/utils/security.py` has **placeholder** `hash_password` / `verify_password` (returns `"hashed_{password}"`). The real implementation lives in `app/core/security.py`. If anything ever imports from `app/utils/security`, passwords are stored in plaintext. | `app/utils/security.py` | Delete this file entirely or make it re-export from `app/core/security`. |
| B2 | **`POST /users` is unprotected** — creates a user without authentication or any permission check. Anyone can create accounts directly, bypassing registration flow. | `app/api/v1/endpoints.py` line 82 | Either remove this endpoint, protect it with `require_permission("users.admin.manage")`, or merge it into the registration flow. |
| B3 | **`datetime.utcnow` is deprecated** — used as default in every model's `created_at`. Python 3.12+ warns about this; it returns a naive datetime. | All models (11 files) | Replace with `datetime.now(UTC)` from `datetime` module, or use `func.now()` from SQLAlchemy for server-side defaults. |

### 3.2 Structural Cleanup

| # | Issue | Location | What to Do |
|---|---|---|---|
| B4 | **User router misnamed** — user CRUD lives in `endpoints.py` but is exported as `users_router`. Every other router matches its filename (`flights.py`, `reservations.py`, `airports.py`). | `app/api/v1/endpoints.py` | Rename file to `users.py`. |
| B5 | **Dead router file** — `app/api/endpoints.py` defines a `main_router` that is never imported by `app/main.py`. | `app/api/endpoints.py` | Delete this file. |
| B6 | **Dead model** — `app/models/example.py` defines an `Example` model that is never used, has no API, and no migration references it. | `app/models/example.py` | Delete this file. |
| B7 | **Duplicate migration directory** — `app/db/migrations/` has its own `env.py` and `script.py.mako` but `alembic.ini` points to `alembic/`. Two migration trees create confusion. | `app/db/migrations/` | Delete `app/db/migrations/` or consolidate into one location. |
| B8 | **Messy migration history** — migration files named `try`, `massage`, `epoc2` suggest experimental runs that were never squashed. | `alembic/versions/` | Squash into clean migrations before the next big feature. |
| B9 | **Auth path inconsistency** — all API routes are under `/api/v1/*` except auth which is at `/auth/*`. Mobile and web clients must use two base URLs. | `app/main.py` line 57 | Move auth to `/api/v1/auth`. |
| B10 | **Inline Pydantic schemas in router** — `endpoints.py` (users router) defines 7 schemas (`ProfileRead`, `ChangePasswordRequest`, etc.) inside the router file instead of in `app/schemas/users.py`. | `app/api/v1/endpoints.py` | Move schemas to `app/schemas/users.py`. |
| B11 | **CORS wide open in dev** — `allow_origins=["*"]` is fine for dev but in production the list is empty `[]`, which means **no CORS at all**, not even the webapp domain. | `app/main.py` line 44 | Add `CORS_ORIGINS` to settings with a comma-separated list for prod/staging. |
| B12 | **No README** — `pyproject.toml` references `readme = "README.md"` but the file does not exist. Description says "ERP and Retail Management System" which does not match the travel product. | Root | Create a real `README.md`. Update `pyproject.toml` description. |
| B13 | **Name confusion** — folder is `mosafer`, Python package is `musafir`, Docker containers are `musafir_*`, FastAPI title is "Musafir ERP System". | Everywhere | Pick **one name** and align everything. |

### 3.3 Minor / Quality

| # | Issue | What to Do |
|---|---|---|
| B14 | `paginate()` helper in `app/utils/helpers.py` does in-memory pagination on full lists — never used by any endpoint (all use SQL `offset`/`limit`). | Delete or keep for future use, but do not mix patterns. |
| B15 | Reservation `total_price` is `float` in the model but `Decimal` in the Flight model. Mixing float and Decimal for money is risky. | Standardize on `Decimal` / `Numeric(12,2)`. |
| B16 | No pagination metadata on list endpoints (total count, next page). Clients cannot build infinite scroll. | Add total count + cursor/offset info to list responses. |

---

## 4. Architecture Decisions Needed

Before starting new epics, decide on these (discuss with yourself or document the choice):

| Decision | Options | Recommendation |
|---|---|---|
| **Background tasks** | Celery + Redis, ARQ + Redis, FastAPI BackgroundTasks, Dramatiq | **ARQ + Redis** — lightweight, async-native, good for Python 3.12. Use for: AI agent calls, notification dispatch, flight status polling. |
| **AI / LLM provider** | OpenAI API, Anthropic Claude, local model via Ollama, LangChain abstraction | Start with **OpenAI API** behind an abstraction layer so you can swap later. |
| **Push notifications** | Firebase Cloud Messaging (FCM), OneSignal, APNs direct | **FCM** — covers both iOS and Android, free tier is generous. |
| **Real-time to client** | WebSocket, SSE (Server-Sent Events), polling | **SSE** for flight status updates (simpler than WS, works through proxies), **polling** as fallback for mobile. |
| **Payment gateway** | Stripe, PayMob (MENA region), Tap Payments | Depends on target market. Start with **Stripe** for global, add PayMob for MENA later. |
| **Caching** | Redis, in-memory (lru_cache) | **Redis** — already needed for task queue. Cache flight searches, airport data, AI responses. |
| **File storage (production)** | Local disk, S3/R2/MinIO | **S3-compatible** (AWS S3 or Cloudflare R2). Local disk does not survive container restarts. |
| **Geolocation / routing** | Google Maps API, Mapbox, OpenRouteService | **Google Maps** for directions + traffic + ETA. Or **Mapbox** if cost-sensitive. |
| **Weather** | OpenWeatherMap, WeatherAPI, Tomorrow.io | **OpenWeatherMap** — free tier covers MVP. |
| **Flight status** | FlightAware AeroAPI, AviationStack, FlightStats (Cirium) | **AviationStack** for free tier MVP, upgrade to **FlightAware** for production accuracy. |

---

## 5. Epic Roadmap (Ordered Tasks)

Each epic is a self-contained deliverable. **Work top to bottom.** Each task inside an epic is a single PR-sized unit.

> **Progress key:** Check the box when a task is done. Track overall epic progress with the counter next to each epic title.

---

### EPIC 0 — Housekeeping & Foundation `[18/18]`

> **Goal:** Clean codebase, fix bugs, establish patterns for everything that follows.

- [x] **0.1** — **Fix B1:** Delete `app/utils/security.py` (placeholder security). Grep the codebase to confirm nothing imports from it. *(Depends on: —)*
- [x] **0.2** — **Fix B2:** Protect or remove `POST /users` (unprotected user creation). *(Depends on: —)*
- [x] **0.3** — **Fix B3:** Replace all `datetime.utcnow` with `datetime.now(UTC)` across all models. *(Depends on: —)*
- [x] **0.4** — **Fix B4:** Rename `app/api/v1/endpoints.py` → `app/api/v1/users.py`. Update `__init__.py` import. *(Depends on: —)*
- [x] **0.5** — **Fix B5 + B6:** Delete `app/api/endpoints.py` and `app/models/example.py`. *(Depends on: —)*
- [x] **0.6** — **Fix B7:** Delete `app/db/migrations/` directory (keep `alembic/`). *(Depends on: —)*
- [x] **0.7** — **Fix B9:** Move auth router from `/auth` to `/api/v1/auth`. *(Depends on: —)*
- [x] **0.8** — **Fix B10:** Move inline schemas from users router to `app/schemas/users.py`. *(Depends on: 0.4)*
- [x] **0.9** — **Fix B11:** Add `CORS_ORIGINS` env var to settings, use it in `main.py`. *(Depends on: —)*
- [x] **0.10** — **Fix B12 + B13:** Create `README.md`, align project name everywhere (picked `mosafer`). Update `pyproject.toml` description. *(Depends on: —)*
- [x] **0.11** — **Fix B15:** Change reservation `total_price` from `float` to `Decimal`/`Numeric(12,2)`. Add migration. *(Depends on: —)*
- [x] **0.12** — **Squash Alembic migrations** into a clean baseline. Or at minimum rename the experimental ones. *(Depends on: 0.6, 0.11)*
- [x] **0.13** — **Add refresh tokens** — create `RefreshToken` model, add `/auth/refresh` endpoint, extend login to return both tokens. *(Depends on: —)*
- [x] **0.14** — **Add email verification** — generate verification token on register, add `/auth/verify-email` endpoint. (Can be a simple token in DB, no email sending yet.) *(Depends on: —)*
- [x] **0.15** — **Add structured logging** — use `structlog` or Python `logging` with JSON formatter. Add request ID middleware. *(Depends on: —)*
- [x] **0.16** — **Add rate limiting** — use `slowapi` or custom middleware on auth endpoints. *(Depends on: —)*
- [x] **0.17** — **Add pagination metadata** to all list endpoints (total count, page info). *(Depends on: —)*
- [x] **0.18** — **Remove Amadeus; Skyscanner-only flight search** — delete Amadeus client/service, related config (`AMADEUS_*`), tests, and router wiring; replace with Skyscanner (Epic 2) or stubs as needed. Rename DB/API fields (e.g. `amadeus_flight_id` → `provider_flight_id`) via migration if you keep storing provider flight IDs. *(Depends on: —)*

---

### EPIC 1 — Infrastructure for New Features `[6/6]`

> **Goal:** Set up Redis, background tasks, and the service patterns needed by all future epics.

- [x] **1.1** — **Add Redis** to `docker-compose.yml` (all three: dev, staging, prod). Add `REDIS_URL` to settings. *(Depends on: Epic 0)*
- [x] **1.2** — **Set up ARQ** (or chosen task queue). Create `app/workers/` package with a worker entry point and a base task pattern. *(Depends on: 1.1)*
- [x] **1.3** — **Create `app/services/external/` package** — establish pattern for external API clients (each API gets its own service file with retry, timeout, error handling). *(Depends on: Epic 0)*
- [x] **1.4** — **Set up caching layer** — create `app/core/cache.py` with Redis-backed cache helpers (get/set/invalidate with TTL). *(Depends on: 1.1)*
- [x] **1.5** — **Create user preferences model** — `UserPreference` table: `user_id`, `home_address`, `home_lat/lng`, `preferred_transport` (car/train/taxi/bus), `language`, `currency`, `notification_enabled`. Add migration, schema, and CRUD endpoint under `/api/v1/users/me/preferences`. *(Depends on: Epic 0)*
- [x] **1.6** — **Add notification infrastructure** — `Notification` model (user_id, type, title, body, read, created_at). Create `/api/v1/notifications` endpoints (list, mark read). FCM integration comes later. *(Depends on: Epic 0)*

---

### EPIC 2 — Mock Flight API Integration & Web Ticket Purchase `[7/7]`

> **Goal:** Web app users can search and "buy" tickets that generate QR codes scannable by the mobile app.

- [x] **2.1** — **Define Mock Flight API data** — create self-contained mock flight data module with realistic offers. Document response format. *(Depends on: —)*
- [x] **2.2** — **Create `app/services/external/mock_flight_service.py`** — search flights, normalize responses into your internal `FlightOfferRead` (or equivalent) schema. *(Depends on: 1.3)*
- [x] **2.3** — **Flight search endpoint (Mock Flight API)** — `/api/v1/flights/search` calls Mock Flight API, returns paginated offers. Add metadata fields the client needs (e.g. source, price, legs). *(Depends on: 2.2)*
- [x] **2.4** — **Create purchase flow** — `POST /api/v1/orders` accepts a selected offer, creates reservation + ticket + QR. This is the formalized version of the existing reservation flow. Add `Order` model if needed, or extend `Reservation` with `payment_status`. *(Depends on: Epic 0)*
- [x] **2.5** — **Enhance QR code content** — QR should encode a deep-link URL or a JSON payload containing: `ticket_number`, `flight_id`, `origin`, `destination`, `departure_at`, `carrier`, `flight_number`, `seat`. This is what the mobile app scans. *(Depends on: 2.4)*
- [x] **2.6** — **Create QR scan endpoint** — `POST /api/v1/tickets/scan` accepts QR payload string, parses it, returns full ticket + flight data. This is the mobile app's entry point after scanning. *(Depends on: 2.5)*
- [x] **2.7** — **Add flight search caching** — cache Mock Flight API results in Redis (TTL: 5–15 min) to reduce API calls and speed up repeated searches. *(Depends on: 1.4, 2.3)*

---

### EPIC 3 — Real-Time Flight Status & Airport Data `[7/7]`

> **Goal:** After a ticket is scanned/imported into the app, show live flight info: gate, counter, delays, terminal.

- [x] **3.1** — **Integrate flight status API** — created `app/services/external/mock_flight_status_service.py`. Returns deterministic mock status by flight number + departure time: departure gate, check-in counter, terminal, delay minutes, status (scheduled / check_in_open / boarding / departed / landed / delayed / canceled). *(Depends on: 1.3)*
- [x] **3.2** — **Create flight status endpoint** — `GET /api/v1/flights/{flight_id}/status` returns live status. Cache in Redis (TTL: 2 min). *(Depends on: 3.1, 1.4)*
- [x] **3.3** — **Create flight status polling worker** — ARQ cron task that polls status for all flights departing in the next 24 hours every 3 minutes. Stores latest status in Redis. *(Depends on: 1.2, 3.1)*
- [x] **3.4** — **Enrich airport model** — added `latitude`, `longitude`, `terminal_info` (JSON), `amenities` (JSON), `map_url` to the Airport model. Seed data for 10 airports (AMM, DXB, IST, CAI, JED, LHR, JFK, RUH, CDG, FRA). *(Depends on: Epic 0)*
- [x] **3.5** — **Create airport detail endpoint** — `GET /api/v1/airports/{iata}/info` returns full airport info including terminals, amenities, location, and map URL. *(Depends on: 3.4)*
- [x] **3.6** — **SSE endpoint for live updates** — `GET /api/v1/flights/{flight_id}/status/stream` returns Server-Sent Events with status changes, gate updates, delay changes. Polls Redis every 10s, keepalive every 30s, 2h timeout. *(Depends on: 3.2)*
- [x] **3.7** — **Push notification on status change** — polling worker detects status/gate/delay changes and creates Notification records for all users with reservations on that flight. *(Depends on: 1.6, 3.3)*

---

### EPIC 4 — Smart Airport Timer `[6/6]`

> **Goal:** Tell the user exactly when to leave for the airport based on where they are, how they travel, traffic, and weather.

- [x] **4.1** — **Integrate Maps Directions API (Mock)** — created `app/services/external/mock_maps_service.py`. Uses haversine + road factor for distance, mode-based speed (driving/transit/walking/taxi), and simulated rush-hour traffic. *(Depends on: 1.3)*
- [x] **4.2** — **Integrate Weather API (Mock)** — created `app/services/external/mock_weather_service.py`. Deterministic weather seeded by location + date with latitude-band temperature, visibility, and severe alert support. *(Depends on: 1.3)*
- [x] **4.3** — **Create departure time calculator** — `app/services/departure_planner.py`. Combines travel ETA, check-in buffer (2h domestic / 3h international), and weather buffer (15-30 min for rain/snow/storm) to calculate `leave_at`. *(Depends on: 4.1, 4.2, 3.4)*
- [x] **4.4** — **Create departure planner endpoint** — `GET /api/v1/trips/{reservation_id}/departure-plan`. Falls back to user preferences for location and transport mode. Cached in Redis (TTL 5 min). *(Depends on: 4.3)*
- [x] **4.5** — **Create departure alert worker** — ARQ cron task (every 30 min) for flights in next 12h. Escalates urgency: gentle reminder (1-3h) → warning (30-60min) → urgent (<30min). Dedup via Redis. *(Depends on: 1.2, 4.3, 1.6)*
- [x] **4.6** — **"At airport" mode trigger** — `POST /api/v1/trips/{reservation_id}/location-check`. If user within 1 km of airport: returns flight status, airport amenities, gate info, minutes to boarding. Otherwise returns departure plan. *(Depends on: 4.4, 3.5)*

---

### EPIC 5 — AI Travel Agent (Destination Intelligence) `[9/9]`

> **Goal:** Smart AI assistant that creates packing lists, travel tips, and warnings based on destination.

- [x] **5.1** — **Set up LLM integration** — created `app/services/ai/llm_client.py` wrapping `openai.AsyncOpenAI` with `chat()` and `chat_json()` methods. Added `OPENAI_API_KEY` to settings and `openai` dependency. *(Depends on: 1.3)*
- [x] **5.2** — **Design AI prompt templates** — created `app/services/ai/prompts/` with templates for packing list, destination tips, and timeline. Each returns structured JSON via system prompt instructions. *(Depends on: 5.1)*
- [x] **5.3** — **Create packing list generator** — `app/services/ai/packing_agent.py`. Calls OpenAI for categorized packing list (must_have/recommended/optional). Falls back to sensible defaults if API unavailable. *(Depends on: 5.2)*
- [x] **5.4** — **Create packing list endpoint** — `POST /api/v1/trips/{reservation_id}/packing-list`. Cached in Redis (TTL 24h). Returns structured `PackingListResult`. *(Depends on: 5.3, 1.4)*
- [x] **5.5** — **Create destination tips endpoint** — `GET /api/v1/destinations/{iata}/tips`. AI-generated travel tips cached 7 days. Covers visa, currency, language, customs, safety, transport, SIM, tipping. *(Depends on: 5.2, 1.4)*
- [x] **5.6** — **Create trip todo list model** — `TripTodo` table with category, title, priority, is_completed, due_date, source (ai/user). *(Depends on: Epic 0)*
- [x] **5.7** — **Create trip todo endpoints** — full CRUD on `/api/v1/trips/{reservation_id}/todos` plus `POST .../todos/populate` to auto-create from AI packing list. *(Depends on: 5.6, 5.4)*
- [x] **5.8** — **AI-generated timeline** — `POST /api/v1/trips/{reservation_id}/timeline`. Generates preparation timeline via LLM, creates TripTodo records with due_date relative to departure. Cached 24h. *(Depends on: 5.3, 4.3, 5.6)*
- [x] **5.9** — **User feedback loop** — `TripFeedback` model (rating, packing_helpful, missing_items, comments). `POST` and `GET` endpoints at `/api/v1/trips/{reservation_id}/feedback`. *(Depends on: 5.7)*

---

### EPIC 6 — In-Airport Experience `[0/4]`

> **Goal:** Once the user is at the airport, the app becomes a live dashboard.

- [ ] **6.1** — **Airport dashboard endpoint** — `GET /api/v1/trips/{reservation_id}/airport-dashboard`. Returns: flight status, gate, counter, terminal, time to boarding, walk time to gate (estimated), nearby food/shops. *(Depends on: 3.2, 3.5, 4.6)*
- [ ] **6.2** — **Gate proximity suggestions** — based on gate location and time to boarding: if > 60 min → "you have time to explore terminal shops and restaurants"; if 30-60 min → "head towards your gate area, grab food nearby"; if < 30 min → "proceed to gate now". *(Depends on: 6.1)*
- [ ] **6.3** — **Boarding countdown** — real-time countdown to boarding time (boarding usually starts 30-45 min before departure). Factor in known gate info. *(Depends on: 3.2)*
- [ ] **6.4** — **Post-flight transition** — when flight status = "landed", switch app context to: arrival airport info, immigration tips (if international), baggage claim belt (if available from API), local transport options. *(Depends on: 3.3, 5.5)*

---

### EPIC 7 — Payment Integration (Mock) `[6/6]`

> **Goal:** Payment infrastructure with mock provider, ready to swap for Stripe/PayMob when needed.

- [x] **7.1** — **Mock payment provider setup** — added `PAYMENT_PROVIDER` and `PAYMENT_WEBHOOK_SECRET` to settings. Provider set to `"mock"` by default. *(Depends on: —)*
- [x] **7.2** — **Create `app/services/external/mock_payment_service.py`** — `MockPaymentService` with `create_session`, `verify_webhook`, `get_payment_status`, and `refund` methods. Deterministic session IDs seeded from reservation data. *(Depends on: 1.3)*
- [x] **7.3** — **Create payment models** — `Payment` table: `id`, `reservation_id`, `user_id`, `provider`, `provider_payment_id`, `amount` (Numeric 12,2), `currency`, `status` (pending/completed/failed/refunded), `created_at`, `updated_at`. Pydantic schemas: `PaymentCreateRequest`, `PaymentSessionResponse`, `PaymentRead`, `PaymentWebhookPayload`, `RefundResponse`. *(Depends on: Epic 0)*
- [x] **7.4** — **Create payment endpoints** — `POST /api/v1/payments/create-session` (creates Payment + returns mock checkout URL), `POST /api/v1/payments/webhook` (mock callback), `GET /api/v1/payments/{id}` (status check). Registered in router and main app. *(Depends on: 7.2, 7.3)*
- [x] **7.5** — **Connect payment to reservation** — webhook handler updates `Reservation.status` to `PAID` on success or `CANCELED` on failure. Creates in-app notification via `NotificationDispatcher` (push + email for payment_success). *(Depends on: 7.4, Epic 0)*
- [x] **7.6** — **Refund flow** — `POST /api/v1/payments/{id}/refund` validates completed status, calls mock refund, updates Payment to `refunded` and Reservation to `CANCELED`. Dispatches refund notification. *(Depends on: 7.5)*

---

### EPIC 8 — Notifications & Communication (Real FCM + Resend) `[5/5]`

> **Goal:** Push notifications via Firebase Cloud Messaging and transactional email via Resend API.

- [x] **8.1** — **Integrate FCM** — created `app/services/external/fcm_service.py` using real `firebase-admin` SDK. Initialises from `FIREBASE_CREDENTIALS_PATH`. `send_push` and `send_push_multi` methods with graceful fallback if credentials are missing. `DeviceToken` model: `user_id`, `token` (unique), `platform`, `created_at`. *(Depends on: 1.3, 1.6)*
- [x] **8.2** — **Create device token endpoints** — `POST /api/v1/devices/register` (upserts token), `DELETE /api/v1/devices/{token}`. Registered in router and main app. *(Depends on: 8.1)*
- [x] **8.3** — **Integrate Resend email service** — created `app/services/external/email_service.py` using real Resend Python SDK. Added `RESEND_API_KEY` and `RESEND_FROM_EMAIL` to settings. Template methods: `send_booking_confirmation`, `send_payment_receipt`, `send_trip_reminder`. Fallback log if API key missing. *(Depends on: 1.3)*
- [x] **8.4** — **Create notification dispatch service** — `app/services/notification_dispatcher.py` — `dispatch()` fans out to: in-app DB `Notification`, FCM push (for push-worthy events), Resend email (for critical events: payment_success, gate_change, departure_urgent). Event-type mapping determines channels. *(Depends on: 8.1, 8.3, 1.6)*
- [x] **8.5** — **Wire notifications to events** — updated `flight_status_poller.py` and `departure_alert.py` workers to use `NotificationDispatcher` instead of direct `Notification` creation. Updated `payments.py` webhook and refund handlers to dispatch notifications. All channels degrade gracefully if FCM/email unavailable. *(Depends on: 8.4, all prior epics)*

---

### EPIC 9 — Production Hardening `[0/9]`

> **Goal:** Make the system production-ready.

- [ ] **9.1** — **Write integration tests** — auth flow, booking flow, ticket scan, AI agent (mocked), payment webhook (mocked). Target 80%+ coverage. *(Depends on: All epics)*
- [ ] **9.2** — **Add API versioning middleware** — ensure `/api/v1` can coexist with future `/api/v2`. *(Depends on: —)*
- [ ] **9.3** — **File storage migration** — move from local disk to S3-compatible storage for QR images, ticket PDFs, profile pictures, attachments. *(Depends on: —)*
- [ ] **9.4** — **Add health check depth** — `/api/v1/health` should check DB connection, Redis connection, and external API reachability. *(Depends on: 1.1)*
- [ ] **9.5** — **Observability** — add Prometheus metrics endpoint (`/metrics`), structure logs for ELK/Loki, add tracing (OpenTelemetry) for external API calls. *(Depends on: 0.15)*
- [ ] **9.6** — **Security audit** — rate limit all endpoints, validate all file uploads (magic bytes, not just content-type), add request size limits, review CORS config, add security headers middleware. *(Depends on: 0.16)*
- [ ] **9.7** — **Complete CD pipeline** — fill in the deploy steps for staging (Docker Compose on VPS, or Kubernetes). Add database migration step to CI/CD. *(Depends on: Epic 0)*
- [ ] **9.8** — **API documentation** — ensure all endpoints have clear OpenAPI descriptions, request/response examples, and error codes. Generate an API reference page. *(Depends on: All epics)*
- [ ] **9.9** — **Load testing** — use Locust or k6 to test flight search, booking, and status endpoints under load. Identify bottlenecks. *(Depends on: All epics)*

---

## 6. External APIs Reference

Quick reference for all third-party APIs the project will need:

| API | Purpose | Free Tier | Key Link |
|---|---|---|---|
| **Mock Flight API** (built-in mock data) | Flight search & pricing — **mock provider** for web/app booking flow during development | N/A | Internal module `app/services/external/mock_flight_service.py` |
| **AviationStack** | Real-time flight status | 100 calls/month | https://aviationstack.com |
| **FlightAware AeroAPI** | Flight tracking (production) | Paid | https://www.flightaware.com/aeroapi |
| **Google Maps Directions** | Route + traffic + ETA | $200/month credit | https://developers.google.com/maps |
| **OpenWeatherMap** | Weather forecast | 1000 calls/day | https://openweathermap.org/api |
| **OpenAI** | AI agent (packing, tips) | Pay per token | https://platform.openai.com |
| **Firebase (FCM)** | Push notifications | Free | https://firebase.google.com/docs/cloud-messaging |
| **Stripe** | Payment processing | Pay per transaction | https://stripe.com/docs/api |
| **SendGrid / Resend** | Transactional email | 100/day free | https://sendgrid.com |

---

## 7. Non-Functional Requirements

| Requirement | Target |
|---|---|
| API response time (p95) | < 300ms for DB endpoints, < 2s for external API proxies |
| Uptime | 99.5% (staging), 99.9% (production) |
| Test coverage | > 80% line coverage |
| Security | OWASP top 10 addressed, no secrets in code, JWT with refresh rotation |
| Scalability | Stateless API (horizontal scaling), Redis for shared state |
| Data | All timestamps in UTC, all money in Decimal, all IATA codes uppercase |
| Mobile | API responses optimized for mobile (minimal payload, pagination, conditional fields) |
| Offline | Mobile app should cache last-known flight status and todos locally; backend provides ETags / last-modified headers |

---

## Progress Tracker

> Update the fractions below as you check off tasks in each epic.

| Epic | Title | Tasks | Done | Progress |
|---|---|---|---|---|
| 0 | Housekeeping & Foundation | 18 | 18 | `████████████████████` 100% |
| 1 | Infrastructure | 6 | 6 | `████████████████████` 100% |
| 2 | Mock Flight API & Purchase | 7 | 7 | `████████████████████` 100% |
| 3 | Flight Status & Airport | 7 | 7 | `████████████████████` 100% |
| 4 | Smart Airport Timer | 6 | 6 | `████████████████████` 100% |
| 5 | AI Travel Agent | 9 | 9 | `████████████████████` 100% |
| 6 | In-Airport Experience | 4 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| 7 | Payment Integration (Mock) | 6 | 6 | `████████████████████` 100% |
| 8 | Notifications (FCM + Resend) | 5 | 5 | `████████████████████` 100% |
| 9 | Production Hardening | 9 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| | **TOTAL** | **77** | **64** | **83%** |

## Task Summary by Priority

| Priority | Epics | Estimated Effort |
|---|---|---|
| **Now** | Epic 0 (Housekeeping) | 2–3 days |
| **Next** | Epic 1 (Infrastructure) | 3–4 days |
| **Core features** | Epic 2 (Mock Flight API + Purchase) → Epic 3 (Flight Status) → Epic 4 (Airport Timer) | 2–3 weeks |
| **Differentiator** | Epic 5 (AI Agent) → Epic 6 (In-Airport) | 2–3 weeks |
| **Revenue** | Epic 7 (Payments) | 1 week |
| **Polish** | Epic 8 (Notifications) → Epic 9 (Production) | 2–3 weeks |

**Total estimated timeline: 8–12 weeks** working as a developer + AI assistant pair.

---

*This document is the single source of truth for Mosafer's backend roadmap. Update it as tasks are completed.*
