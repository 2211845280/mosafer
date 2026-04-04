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
| **Ticket Purchase (Web)** | Search flights via **Skyscanner**, buy tickets, generate QR codes |
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
| **Flights** | Partial | Admin create/list; **public flight search targets Skyscanner only** (Epic 2). Retire any legacy flight-provider code during housekeeping. |
| **Reservations** | Done | Create booking (upserts flight, validates seat, issues ticket + QR), list user bookings, cancel booking |
| **Tickets** | Done | List/history (with filters), get by number, validate (QR scan flow: valid→used), download PDF, upload attachments, admin report |
| **QR System** | Done | QR PNG generation per ticket, QR content encoding, PDF embedding |
| **Testing** | Partial | Smoke tests (root, health), unit tests (seat validation, flight-offer normalization helpers). No integration tests for auth/booking flows |
| **CI Pipeline** | Done | Ruff lint + format, pytest with Postgres service, coverage upload, Docker build test |
| **CD Pipeline** | Scaffold | Builds and pushes to GHCR; deploy steps are placeholder `echo` commands |

### 2.2 What Does NOT Exist Yet

- No AI agent / LLM integration of any kind
- No destination intelligence (packing lists, local availability info)
- No user location / geolocation handling
- No transport mode or route calculation
- No traffic or weather API integration
- No real-time flight status (delays, gates, counters)
- No push notifications / WebSocket for live alerts
- No Skyscanner integration yet (web ticket purchase); remove legacy flight-search code when wiring Skyscanner
- No payment processing
- No webapp-to-app QR bridge (the current QR is ticket-number-only, not a deep link with full flight data)
- No user preferences / travel profile storage
- No background task system (Celery, ARQ, or similar)
- No structured logging or observability
- No rate limiting
- No email verification on registration
- No refresh tokens (only short-lived access tokens)
- No README

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

### EPIC 0 — Housekeeping & Foundation `[0/18]`

> **Goal:** Clean codebase, fix bugs, establish patterns for everything that follows.

- [ ] **0.1** — **Fix B1:** Delete `app/utils/security.py` (placeholder security). Grep the codebase to confirm nothing imports from it. *(Depends on: —)*
- [ ] **0.2** — **Fix B2:** Protect or remove `POST /users` (unprotected user creation). *(Depends on: —)*
- [ ] **0.3** — **Fix B3:** Replace all `datetime.utcnow` with `datetime.now(UTC)` across all models. *(Depends on: —)*
- [ ] **0.4** — **Fix B4:** Rename `app/api/v1/endpoints.py` → `app/api/v1/users.py`. Update `__init__.py` import. *(Depends on: —)*
- [ ] **0.5** — **Fix B5 + B6:** Delete `app/api/endpoints.py` and `app/models/example.py`. *(Depends on: —)*
- [ ] **0.6** — **Fix B7:** Delete `app/db/migrations/` directory (keep `alembic/`). *(Depends on: —)*
- [ ] **0.7** — **Fix B9:** Move auth router from `/auth` to `/api/v1/auth`. *(Depends on: —)*
- [ ] **0.8** — **Fix B10:** Move inline schemas from users router to `app/schemas/users.py`. *(Depends on: 0.4)*
- [ ] **0.9** — **Fix B11:** Add `CORS_ORIGINS` env var to settings, use it in `main.py`. *(Depends on: —)*
- [ ] **0.10** — **Fix B12 + B13:** Create `README.md`, align project name everywhere (pick `mosafer` or `musafir`). Update `pyproject.toml` description. *(Depends on: —)*
- [ ] **0.11** — **Fix B15:** Change reservation `total_price` from `float` to `Decimal`/`Numeric(12,2)`. Add migration. *(Depends on: —)*
- [ ] **0.12** — **Squash Alembic migrations** into a clean baseline. Or at minimum rename the experimental ones. *(Depends on: 0.6, 0.11)*
- [ ] **0.13** — **Add refresh tokens** — create `RefreshToken` model, add `/auth/refresh` endpoint, extend login to return both tokens. *(Depends on: —)*
- [ ] **0.14** — **Add email verification** — generate verification token on register, add `/auth/verify-email` endpoint. (Can be a simple token in DB, no email sending yet.) *(Depends on: —)*
- [ ] **0.15** — **Add structured logging** — use `structlog` or Python `logging` with JSON formatter. Add request ID middleware. *(Depends on: —)*
- [ ] **0.16** — **Add rate limiting** — use `slowapi` or custom middleware on auth endpoints. *(Depends on: —)*
- [ ] **0.17** — **Add pagination metadata** to all list endpoints (total count, page info). *(Depends on: —)*
- [ ] **0.18** — **Remove Amadeus; Skyscanner-only flight search** — delete Amadeus client/service, related config (`AMADEUS_*`), tests, and router wiring; replace with Skyscanner (Epic 2) or stubs as needed. Rename DB/API fields (e.g. `amadeus_flight_id` → neutral name) via migration if you keep storing provider flight IDs. *(Depends on: —)*

---

### EPIC 1 — Infrastructure for New Features `[0/6]`

> **Goal:** Set up Redis, background tasks, and the service patterns needed by all future epics.

- [ ] **1.1** — **Add Redis** to `docker-compose.yml` (all three: dev, staging, prod). Add `REDIS_URL` to settings. *(Depends on: Epic 0)*
- [ ] **1.2** — **Set up ARQ** (or chosen task queue). Create `app/workers/` package with a worker entry point and a base task pattern. *(Depends on: 1.1)*
- [ ] **1.3** — **Create `app/services/external/` package** — establish pattern for external API clients (each API gets its own service file with retry, timeout, error handling). *(Depends on: Epic 0)*
- [ ] **1.4** — **Set up caching layer** — create `app/core/cache.py` with Redis-backed cache helpers (get/set/invalidate with TTL). *(Depends on: 1.1)*
- [ ] **1.5** — **Create user preferences model** — `UserPreference` table: `user_id`, `home_address`, `home_lat/lng`, `preferred_transport` (car/train/taxi/bus), `language`, `currency`, `notification_enabled`. Add migration, schema, and CRUD endpoint under `/api/v1/users/me/preferences`. *(Depends on: Epic 0)*
- [ ] **1.6** — **Add notification infrastructure** — `Notification` model (user_id, type, title, body, read, created_at). Create `/api/v1/notifications` endpoints (list, mark read). FCM integration comes later. *(Depends on: Epic 0)*

---

### EPIC 2 — Skyscanner Integration & Web Ticket Purchase `[0/7]`

> **Goal:** Web app users can search and "buy" tickets that generate QR codes scannable by the mobile app.

- [ ] **2.1** — **Research & register for Skyscanner API** (Skyscanner Flights API via RapidAPI or direct partner). Document auth method, rate limits, and response format. *(Depends on: —)*
- [ ] **2.2** — **Create `app/services/external/skyscanner_service.py`** — search flights, normalize responses into your internal `FlightOfferRead` (or equivalent) schema. *(Depends on: 1.3)*
- [ ] **2.3** — **Flight search endpoint (Skyscanner-only)** — `/api/v1/flights/search` calls Skyscanner, returns paginated offers. Add metadata fields the client needs (e.g. source, price, legs). *(Depends on: 2.2)*
- [ ] **2.4** — **Create purchase flow** — `POST /api/v1/orders` accepts a selected offer, creates reservation + ticket + QR. This is the formalized version of the existing reservation flow. Add `Order` model if needed, or extend `Reservation` with `payment_status`. *(Depends on: Epic 0)*
- [ ] **2.5** — **Enhance QR code content** — QR should encode a deep-link URL or a JSON payload containing: `ticket_number`, `flight_id`, `origin`, `destination`, `departure_at`, `carrier`, `flight_number`, `seat`. This is what the mobile app scans. *(Depends on: 2.4)*
- [ ] **2.6** — **Create QR scan endpoint** — `POST /api/v1/tickets/scan` accepts QR payload string, parses it, returns full ticket + flight data. This is the mobile app's entry point after scanning. *(Depends on: 2.5)*
- [ ] **2.7** — **Add flight search caching** — cache Skyscanner results in Redis (TTL: 5–15 min) to reduce API calls and speed up repeated searches. *(Depends on: 1.4, 2.3)*

---

### EPIC 3 — Real-Time Flight Status & Airport Data `[0/7]`

> **Goal:** After a ticket is scanned/imported into the app, show live flight info: gate, counter, delays, terminal.

- [ ] **3.1** — **Integrate flight status API** — create `app/services/external/flight_status_service.py`. Fetch real-time status by flight number + date: departure gate, check-in counter, terminal, delay minutes, status (on-time / delayed / canceled / boarding / departed / landed). *(Depends on: 1.3)*
- [ ] **3.2** — **Create flight status endpoint** — `GET /api/v1/flights/{flight_id}/status` returns live status. Cache in Redis (TTL: 2 min). *(Depends on: 3.1, 1.4)*
- [ ] **3.3** — **Create flight status polling worker** — background task that polls status for all flights departing in the next 24 hours every 3-5 minutes. Stores latest status in DB/Redis. *(Depends on: 1.2, 3.1)*
- [ ] **3.4** — **Enrich airport model** — add `latitude`, `longitude`, `terminal_info` (JSON), `amenities` (JSON), `map_url` to the Airport model. Seed from a public airport database (OurAirports CSV or similar). *(Depends on: Epic 0)*
- [ ] **3.5** — **Create airport detail endpoint** — `GET /api/v1/airports/{iata}/info` returns full airport info including terminals, gates area, food options near gates. *(Depends on: 3.4)*
- [ ] **3.6** — **SSE endpoint for live updates** — `GET /api/v1/flights/{flight_id}/status/stream` returns Server-Sent Events with gate changes, delay updates, boarding calls. Client connects after scanning ticket. *(Depends on: 3.2)*
- [ ] **3.7** — **Push notification on status change** — when flight status polling detects a change (gate change, delay, boarding), send push notification to all users with tickets on that flight. *(Depends on: 1.6, 3.3)*

---

### EPIC 4 — Smart Airport Timer `[0/6]`

> **Goal:** Tell the user exactly when to leave for the airport based on where they are, how they travel, traffic, and weather.

- [ ] **4.1** — **Integrate Google Maps Directions API** — create `app/services/external/maps_service.py`. Given origin (lat/lng), destination (airport lat/lng), and mode (driving/transit/walking), return ETA in minutes and distance. Must support departure_time for traffic prediction. *(Depends on: 1.3)*
- [ ] **4.2** — **Integrate weather API** — create `app/services/external/weather_service.py`. Fetch weather for a location at a given time. Return: condition (rain/snow/clear), temperature, visibility, severe weather alerts. *(Depends on: 1.3)*
- [ ] **4.3** — **Create departure time calculator** — `app/services/departure_planner.py`. Inputs: user location, airport IATA (→ lat/lng), flight departure time, transport mode. Logic: `leave_at = departure_time - check_in_buffer (2h domestic / 3h international) - travel_eta - weather_buffer (add 15-30 min if rain/snow)`. Return: `leave_at`, `travel_minutes`, `weather_warning`, `transport_mode`. *(Depends on: 4.1, 4.2, 3.4)*
- [ ] **4.4** — **Create departure planner endpoint** — `GET /api/v1/trips/{reservation_id}/departure-plan`. Returns the full departure recommendation. *(Depends on: 4.3)*
- [ ] **4.5** — **Create departure alert worker** — background task that runs for flights in the next 12 hours. Recalculates departure time every 30 min (traffic changes). Sends notification when it's time to leave. Escalates urgency (gentle reminder → warning → urgent). *(Depends on: 1.2, 4.3, 1.6)*
- [ ] **4.6** — **"At airport" mode trigger** — when user's location is within 1 km of the airport (client sends location update), switch the app context to show in-airport data: gate, counter, time-to-boarding, food/shops nearby. *(Depends on: 4.4, 3.5)*

---

### EPIC 5 — AI Travel Agent (Destination Intelligence) `[0/9]`

> **Goal:** Smart AI assistant that creates packing lists, travel tips, and warnings based on destination.

- [ ] **5.1** — **Set up LLM integration** — create `app/services/ai/llm_client.py` with an abstraction over OpenAI (or chosen provider). Support: system prompt, user message, structured JSON output. Add `OPENAI_API_KEY` to settings. *(Depends on: 1.3)*
- [ ] **5.2** — **Design AI prompt templates** — create `app/services/ai/prompts/` directory. Write prompt templates for: packing list, destination tips, item availability check. Use Jinja2 or simple string templates with placeholders for: `destination_country`, `destination_city`, `trip_duration`, `travel_dates`, `traveler_origin_country`. *(Depends on: 5.1)*
- [ ] **5.3** — **Create packing list generator** — `app/services/ai/packing_agent.py`. Takes destination + dates + user origin country. Returns categorized list: `must_have` (items unavailable/expensive at destination), `recommended`, `optional`. Examples: sunscreen brands, specific deodorants, medications, adapters, specific clothing. *(Depends on: 5.2)*
- [ ] **5.4** — **Create packing list endpoint** — `POST /api/v1/trips/{reservation_id}/packing-list`. Calls AI agent, caches result in Redis (TTL: 24h), returns structured list. *(Depends on: 5.3, 1.4)*
- [ ] **5.5** — **Create destination tips endpoint** — `GET /api/v1/destinations/{iata}/tips`. Returns AI-generated tips: visa requirements, currency, language, customs, safety, transportation, SIM card, tipping culture. Cache aggressively (TTL: 7 days). *(Depends on: 5.2, 1.4)*
- [ ] **5.6** — **Create trip todo list model** — `TripTodo` table: `id`, `reservation_id`, `user_id`, `category` (packing/document/task), `title`, `priority` (must/recommended/optional), `is_completed`, `due_date`, `source` (ai/user). *(Depends on: Epic 0)*
- [ ] **5.7** — **Create trip todo endpoints** — full CRUD on `/api/v1/trips/{reservation_id}/todos`. Auto-populated from AI packing list, user can add/edit/complete/delete items. *(Depends on: 5.6, 5.4)*
- [ ] **5.8** — **AI-generated timeline** — given a trip, generate a timeline: "7 days before: check visa status", "3 days before: buy items from packing list", "1 day before: pack bags, charge devices", "Day of: leave at X". Store as todos with due dates. *(Depends on: 5.3, 4.3, 5.6)*
- [ ] **5.9** — **User feedback loop** — after a trip, ask user "was the packing list helpful? anything missing?" Store feedback. Use it to improve prompts over time (append to prompt context or fine-tune). *(Depends on: 5.7)*

---

### EPIC 6 — In-Airport Experience `[0/4]`

> **Goal:** Once the user is at the airport, the app becomes a live dashboard.

- [ ] **6.1** — **Airport dashboard endpoint** — `GET /api/v1/trips/{reservation_id}/airport-dashboard`. Returns: flight status, gate, counter, terminal, time to boarding, walk time to gate (estimated), nearby food/shops. *(Depends on: 3.2, 3.5, 4.6)*
- [ ] **6.2** — **Gate proximity suggestions** — based on gate location and time to boarding: if > 60 min → "you have time to explore terminal shops and restaurants"; if 30-60 min → "head towards your gate area, grab food nearby"; if < 30 min → "proceed to gate now". *(Depends on: 6.1)*
- [ ] **6.3** — **Boarding countdown** — real-time countdown to boarding time (boarding usually starts 30-45 min before departure). Factor in known gate info. *(Depends on: 3.2)*
- [ ] **6.4** — **Post-flight transition** — when flight status = "landed", switch app context to: arrival airport info, immigration tips (if international), baggage claim belt (if available from API), local transport options. *(Depends on: 3.3, 5.5)*

---

### EPIC 7 — Payment Integration `[0/6]`

> **Goal:** Actually charge users for ticket purchases on the web app.

- [ ] **7.1** — **Choose and register payment provider** (Stripe / PayMob / Tap). Set up test/sandbox account. Document webhooks. *(Depends on: —)*
- [ ] **7.2** — **Create `app/services/external/payment_service.py`** — create payment intent/session, verify webhook signature, handle success/failure callbacks. *(Depends on: 1.3)*
- [ ] **7.3** — **Create payment models** — `Payment` table: `id`, `reservation_id`, `user_id`, `provider`, `provider_payment_id`, `amount`, `currency`, `status` (pending/completed/failed/refunded), `created_at`. *(Depends on: Epic 0)*
- [ ] **7.4** — **Create payment endpoints** — `POST /api/v1/payments/create-session` (returns provider checkout URL/client secret), `POST /api/v1/payments/webhook` (provider callback), `GET /api/v1/payments/{id}` (status check). *(Depends on: 7.2, 7.3)*
- [ ] **7.5** — **Connect payment to reservation** — after successful payment webhook, update reservation status to `PAID`, finalize ticket. If payment fails/expires, auto-cancel reservation after timeout. *(Depends on: 7.4, Epic 0)*
- [ ] **7.6** — **Refund flow** — when a paid reservation is canceled, initiate refund through payment provider. *(Depends on: 7.5)*

---

### EPIC 8 — Notifications & Communication `[0/5]`

> **Goal:** Push notifications, email, and in-app notifications.

- [ ] **8.1** — **Integrate FCM** — create `app/services/external/fcm_service.py`. Store user device tokens (`DeviceToken` model: user_id, token, platform, created_at). *(Depends on: 1.3, 1.6)*
- [ ] **8.2** — **Create device token endpoints** — `POST /api/v1/devices/register`, `DELETE /api/v1/devices/{token}`. *(Depends on: 8.1)*
- [ ] **8.3** — **Integrate email service** — create `app/services/external/email_service.py` (SendGrid, AWS SES, or Resend). Send: verification email, booking confirmation, trip reminders. *(Depends on: 1.3)*
- [ ] **8.4** — **Create notification dispatch service** — `app/services/notification_dispatcher.py` — fan out to: in-app DB notification, push (FCM), email. Each notification type has a template. *(Depends on: 8.1, 8.3, 1.6)*
- [ ] **8.5** — **Wire notifications to events** — booking confirmed, payment success, flight status change, departure reminder, gate change, boarding alert. Each event triggers the dispatcher. *(Depends on: 8.4, all prior epics)*

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
| **Skyscanner** (e.g. RapidAPI or official partner API) | Flight search & pricing — **sole provider** for web/app booking flow | Varies by product | Register via RapidAPI or Skyscanner for Business / partner docs |
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
| 0 | Housekeeping & Foundation | 18 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| 1 | Infrastructure | 6 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| 2 | Skyscanner & Purchase | 7 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| 3 | Flight Status & Airport | 7 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| 4 | Smart Airport Timer | 6 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| 5 | AI Travel Agent | 9 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| 6 | In-Airport Experience | 4 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| 7 | Payment Integration | 6 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| 8 | Notifications | 5 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| 9 | Production Hardening | 9 | 0 | `░░░░░░░░░░░░░░░░░░░░` 0% |
| | **TOTAL** | **77** | **0** | **0%** |

## Task Summary by Priority

| Priority | Epics | Estimated Effort |
|---|---|---|
| **Now** | Epic 0 (Housekeeping) | 2–3 days |
| **Next** | Epic 1 (Infrastructure) | 3–4 days |
| **Core features** | Epic 2 (Skyscanner + Purchase) → Epic 3 (Flight Status) → Epic 4 (Airport Timer) | 2–3 weeks |
| **Differentiator** | Epic 5 (AI Agent) → Epic 6 (In-Airport) | 2–3 weeks |
| **Revenue** | Epic 7 (Payments) | 1 week |
| **Polish** | Epic 8 (Notifications) → Epic 9 (Production) | 2–3 weeks |

**Total estimated timeline: 8–12 weeks** working as a developer + AI assistant pair.

---

*This document is the single source of truth for Mosafer's backend roadmap. Update it as tasks are completed.*
