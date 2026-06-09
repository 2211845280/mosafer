# Airport Indoor Map — Issues & Backlog

Work items for IST airport experience, indoor map (OpenLevelUp embed), gate assignment, routing simulation, amenity highlights, and **Google Maps route/traffic to the airport**.

**Related areas:** `Flutter/app/lib/features/trips/presentation/airport_indoor_map/`, `Flutter/app/lib/features/trips/presentation/airport_experience/`, `Flutter/app/lib/features/trips/presentation/plan_departure/`, `Flutter/app/lib/features/trips/presentation/on_way/`, `app/api/v1/trips.py`, `app/services/departure_planner.py`, `app/services/external/google_routes_service.py`

---

## Review demo scenario (IST outbound)

Canonical end-to-end path for graduation / review demos. **Route origin is fixed**; **everything after the airport approach uses the active ticket/reservation** so all screens stay consistent.

| Leg | Source | Value |
|-----|--------|--------|
| **Start (route origin)** | Fixed demo point | **Taksim Square**, Istanbul — `41.0369, 28.9850` |
| **End (route destination)** | Ticket / flight | **IST** (Istanbul Airport) — airport coords from DB / API (`airport_lat`, `airport_lng`) |
| **Flight number, carrier, times** | Ticket / reservation | From seeded or booked ticket (e.g. `TK0244`) |
| **Departure gate, terminal** | Ticket + flight status API | Same gate on ticket, airport experience, indoor map (Issue 1) |
| **Leave-at, travel time, traffic, polyline** | `departure-plan` API | Computed **Taksim → IST** using ticket’s `departure_at` and transport mode |
| **Indoor map level, gate overlay** | Ticket gate | OpenLevelUp level + route simulation to assigned gate (Issue 2) |
| **Check-in / amenities (Issues 3–4)** | Ticket gate + flight context | Gate and POI highlights derived from the same reservation |

### Rules

1. **Do not invent** gate, terminal, or flight times in Flutter — read them from the **active trip / ticket** payload (or `departure-plan` / `airport-dashboard` responses tied to `reservation_id`).
2. **Default origin for demos** when GPS is unavailable or on Web: use **Taksim Square** (not generic lat/lng). Live GPS may override on device; review seed should set `home_lat` / `home_lng` to Taksim for the demo traveler.
3. **Destination airport** always comes from the ticket’s **origin IATA** (IST for outbound review trips), not hardcoded in UI copy alone.
4. Indoor map, “Go to gate”, coffee/quick bites, and check-in simulation must all reference the **same gate** returned for that ticket.

### Example review trip

- **Route:** Taksim Square → IST (~45–55 km by road; ETA/traffic from Google Routes or mock).
- **Ticket:** IST → LHR, flight `TK0244`, gate **G12** (see `istanbul_gate_data.py` / seed).
- **Flow:** Plan Departure (leave time) → On Way (map + traffic) → Airport Experience → Indoor map (gate route) → optional arrival/check-in (Issue 3).

---

## Issue 1 — Assign real IST gate numbers

**Priority:** High  
**Type:** Backend + data  
**Status:** Completed

### Problem

Mock flight status and seeded trips use synthetic gates (e.g. derived from flight number hash) that may not match real gates at Istanbul Airport (IST). Indoor map and “go to gate” flows should use gates that actually exist in IST terminal data (OpenStreetMap / OpenLevelUp).

### Scope

- [x] Define a canonical list of valid IST gates (e.g. from `airport_seed_data.py` terminal_info or OSM `level` / gate tags for IST).
- [x] Update `MockFlightStatusService` (or trip/airport experience payload) to return only gates from that list for `origin_iata == IST`.
- [x] Align seed data (`app/seed/istanbul_review_trips.py`) and demo flights so assigned gates exist on the indoor map.
- [x] Document gate format (e.g. `G12`, `A15`) and level mapping if gates span floors.

### Acceptance criteria

- For IST departures, API returns a gate string that appears on OpenLevelUp at the correct level.
- No gate like `Z99` or impossible labels for IST demo/review trips.
- Flutter displays the same gate as backend on ticket, airport experience, and indoor map.

### Notes

- Implemented in `app/services/istanbul_gate_data.py` and `tests/test_ist_gates.py`.

---

## Issue 2 — Fix airport map page UI/UX and make “Go to gate” work

**Priority:** High  
**Type:** Flutter (UI/UX + behavior)  
**Status:** Completed

### Problem

Indoor map screen UX is rough (cropped OpenLevelUp chrome, overlapping controls). “Route to gate” / “Go to gate” is a visual simulation only and does not navigate the embedded map or center on the assigned gate.

### Scope

- [x] Redesign `AirportIndoorMapPage` layout: clear hierarchy (header, level chips, map, primary CTA, secondary info).
- [x] Wire **Go to gate** (or **Route to gate**) to real behavior:
  - Open correct OpenLevelUp level for the gate.
  - Center map on IST terminal area (and gate if coordinates known).
  - Enable route simulation overlay when user taps CTA.
- [x] Improve loading/error/unsupported-IST states.
- [x] Localize strings (move hardcoded English to `app_en.arb` / `app_ar.arb`).
- [x] Verify layout on Web, Android, and iOS (crop offsets may differ per platform).

### Acceptance criteria

- User taps **Go to gate** → map shows correct level + route simulation to the flight’s gate (from trip/active reservation).
- No dead buttons; primary action is obvious on first open.
- Cropped OpenLevelUp UI does not clip essential map controls.

### Files

- `Flutter/app/lib/features/trips/presentation/airport_indoor_map/airport_indoor_map_page.dart`
- `Flutter/app/lib/features/trips/presentation/airport_indoor_map/open_level_up_view*.dart`
- `Flutter/app/lib/features/trips/presentation/airport_experience/airport_experience_page.dart`

---

## Issue 3 — “I arrived at airport” + check-in simulation

**Priority:** Medium  
**Type:** Flutter + optional API  
**Status:** Completed

### Problem

Airport experience lacks a clear moment when the user marks arrival and goes through a simulated check-in before heading to the gate.

### Scope

- [x] Add button: **I arrived at the airport** (or equivalent AR/EN).
- [x] On tap:
  - Show assigned **gate number** prominently (from flight status / reservation).
  - Run a **simulated check-in** flow (steps: arrived → check-in open → boarding pass ready → proceed to security → go to gate).
- [x] Persist step in session or local state (and optionally sync to backend later).
- [x] Gate display must use Issue 1 real IST gate.
- [x] Link from check-in completion to indoor map with gate pre-selected.

### Acceptance criteria

- User can activate arrival mode from airport experience or map entry point.
- Gate is visible after arrival without opening a separate screen hunt.
- Check-in simulation is clearly labeled as demo/simulated (not real airline check-in).
- State survives brief navigation away (e.g. `SharedPreferences` or trip controller).

### UX suggestions

- Bottom sheet or stepped card on `airport_experience_page.dart`.
- Disable repeat spam; allow reset for demo.

### Files

- `Flutter/app/lib/features/trips/presentation/airport_experience/airport_experience_page.dart`
- `Flutter/app/lib/features/trips/presentation/airport_experience/airport_arrival_store.dart`

---

## Issue 4 — Coffee & quick bites — nearest cafe to gate on map

**Priority:** Medium  
**Type:** Flutter + data (highlights)  
**Status:** Completed

### Problem

“Coffee points” and “quick bites” (or similar shortcuts) in airport experience do not open the map or highlight nearest relevant POIs relative to the user’s gate.

### Scope

- [x] Define amenity categories: **coffee**, **quick bites** (and map to OSM tags or static POI list for IST).
- [x] For active IST trip + known gate:
  - Open indoor map at correct level.
  - **Highlight only** nearest matching POI(s) to gate (overlay pins/labels; no full routing engine required for v1).
- [x] Buttons in airport experience navigate to map with `highlight=coffee` or `highlight=food` query/state.
- [x] Reuse or extend backend `airport-indoor-map` response with POI list per level, or static IST amenity coordinates until Overpass POIs are wired.

### Acceptance criteria

- Tap **Coffee** → map opens with one or more cafe highlights near gate path.
- Tap **Quick bites** → map opens with food/snack highlights near gate.
- Highlights are visually distinct from route-to-gate line (Issue 2).
- Works for IST only; other airports show unsupported message.

### Dependencies

- Issue 1 (real gate) for “nearest to gate” logic.
- Issue 2 (map UX + navigation params).

### Notes

- v1 can use fixed POI coordinates per IST level; v2 can query Overpass by amenity tag.

### Files

- `app/services/istanbul_indoor_highlights.py`
- `app/services/istanbul_indoor_fallback.py`
- `Flutter/app/lib/features/trips/presentation/airport_indoor_map/airport_indoor_map_page.dart`
- `Flutter/app/lib/features/trips/presentation/airport_indoor_map/airport_indoor_map_navigation.dart`

---

## Issue 5 — Google Maps integration: routes, traffic, ETA to airport

**Priority:** High  
**Type:** Backend + Flutter  
**Status:** Completed

### Problem

The app needs **real route calculations** (distance, ETA, traffic-aware travel time, leave-at recommendation) from the user’s location to the departure airport. For **review demos**, the route origin is **Taksim Square → IST**; flight times, gate, terminal, and leave-at math must follow the **active ticket/reservation**, not hardcoded UI values.

Backend had Google Routes wired but often fell back to **mock** because env vars were misaligned (`GOOGLE_MAPS_API_KEY` vs `GOOGLE_MAPS_SERVER_API_KEY`, `GOOGLE_ROUTES_ENABLED` not passed to Docker). Flutter **Plan Departure** showed decorative “Live traffic” without API data; **On Way** had Google Map + polyline but omitted traffic level and pre-load route before tracking.

### Architecture (current)

| Layer | Role |
|-------|------|
| **Backend** `GoogleRoutesService` | Routes API v2, `TRAFFIC_AWARE`, polyline, `traffic_level` |
| **Backend** `DeparturePlanner` | leave-at = flight − (check-in buffer + travel + weather) |
| **API** `GET /trips/{id}/departure-plan` | Returns `travel_minutes`, `distance_km`, `traffic_level`, `encoded_polyline`, `route_provider`, coords |
| **Flutter** `plan_departure_page` | Leave time, distance, traffic from API |
| **Flutter** `on_way_page` | Google Map polyline, stats, **Open in Google Maps** |
| **Flutter** `maps_service` | External turn-by-turn via Google Maps app |

API keys:

- **Server:** `GOOGLE_MAPS_SERVER_API_KEY` + `GOOGLE_ROUTES_ENABLED=true` (Routes API enabled in GCP).
- **Client (mobile):** `GOOGLE_MAPS_API_KEY` in Android/iOS for `google_maps_flutter` tiles.
- **Dev fallback:** if only `GOOGLE_MAPS_API_KEY` is set, backend copies it to server key (`config.py`).

### Scope

- [x] Document integration and env requirements (this issue).
- [x] Document **Taksim Square → IST** as canonical demo route; ticket drives flight/gate/times (see [Review demo scenario](#review-demo-scenario-ist-outbound)).
- [x] Backend: `GOOGLE_MAPS_API_KEY` → server key fallback; pass Google env through `docker-compose.yml` / prod.
- [x] Flutter Plan Departure: show **distance**, **traffic level**, route summary from API (not static badge).
- [x] Flutter On Way: preload route on open; show **traffic**; button **Open in Google Maps** with lat/lng.
- [x] Seed demo traveler `home_lat` / `home_lng` = Taksim Square (`41.0369`, `28.9850`) in `istanbul_review_trips` / preferences.
- [x] Flutter fallback when no GPS (Web / denied permission): use Taksim coords for `departure-plan` requests tied to active ticket.
- [x] Ensure Plan Departure / On Way labels show ticket origin airport (IST) and pull `departure_at`, gate from reservation — no duplicate mock strings.
- [x] Enable in local `.env`: `GOOGLE_ROUTES_ENABLED=true` and server key (or shared `GOOGLE_MAPS_API_KEY`).
- [ ] Optional: replace Plan Departure decorative map card with embedded `GoogleMap` + polyline (same as On Way).
- [ ] Optional: traffic-colored polyline on On Way map.

### Acceptance criteria

- Demo route is **Taksim Square → IST**; `departure-plan` uses ticket `departure_at` for traffic-aware ETA and leave-at.
- Gate, terminal, flight number on Plan Departure / On Way / Airport Experience / indoor map **match the active ticket**.
- With Google Routes enabled, `departure-plan` returns `route_provider: "google"` and realistic distance/ETA for Taksim → IST.
- Plan Departure shows leave time, travel minutes, distance, and traffic (low/moderate/heavy).
- On Way draws server polyline on map; stats match API; user can open external Google Maps directions (Taksim → IST when demo origin applies).
- Without Google key, mock provider still works (`route_provider: "mock"`) with no crash.

### Files

- `app/core/config.py`
- `app/services/external/google_routes_service.py`
- `app/services/departure_planner.py`
- `docker-compose.yml`, `docker-compose.prod.yml`, `.env.production.example`
- `Flutter/app/lib/features/trips/presentation/plan_departure/plan_departure_page.dart`
- `Flutter/app/lib/features/trips/presentation/on_way/on_way_page.dart`
- `Flutter/app/lib/core/services/maps_service.dart`
- `Flutter/app/lib/core/utils/departure_plan_formatters.dart`

### Setup checklist

1. GCP: enable **Routes API** (and Maps SDK for Android/iOS for client map).
2. `.env`: `GOOGLE_ROUTES_ENABLED=true`, `GOOGLE_MAPS_SERVER_API_KEY=...` (or `GOOGLE_MAPS_API_KEY` for dev).
3. Restart API container / uvicorn after env change.
4. Seed IST review trips (`scripts/seed_istanbul_review.py`); confirm demo traveler home = Taksim when implemented.
5. Verify with Taksim origin:  
   `GET /api/v1/trips/{reservation_id}/departure-plan?lat=41.0369&lng=28.9850`  
   → `route_provider` is `google` (or `mock`), `airport_lat`/`airport_lng` point to IST, leave-at reflects ticket `departure_at`.

---

## Suggested implementation order

| Order | Issue | Rationale |
|-------|--------|-----------|
| 1 | #1 Real IST gates | Foundation for map, routing, and amenities |
| 2 | #2 Map UX + Go to gate | Core user path |
| 3 | #5 Google Maps routes/traffic | Travel to airport before indoor map |
| 4 | #3 Arrival + check-in sim | Builds on gate + map entry |
| 5 | #4 Coffee / quick bites | Uses gate + map highlights |

---

## Out of scope (for now)

- Full indoor pathfinding (A* on OSM graph) — current route line is **simulation only**.
- Embedding OpenLevelUp routing API (not exposed via iframe).
- Real airline check-in integration.

---

## Testing checklist (when closing issues)

- [ ] Book or seed IST → LHR (or any IST outbound) trip; note `reservation_id`, flight, and gate from **ticket**.
- [ ] Plan Departure: route **Taksim Square → IST**; leave time, distance, traffic from API; times align with ticket departure.
- [ ] On Way: polyline Taksim → IST; stats match API; Open in Google Maps opens correct endpoints.
- [ ] Gate on ticket = gate on Airport Experience = gate on indoor map (**Go to gate**).
- [ ] Open Airport Experience → indoor map.
- [ ] Confirm gate exists on OpenLevelUp at selected level.
- [ ] **Go to gate** centers map and shows route overlay to ticket gate.
- [ ] **I arrived** shows same gate + check-in steps (Issue 3).
- [ ] **Coffee** / **Quick bites** open map with highlights near **ticket gate** (Issue 4).

---

*Created for Mosafer review app — IST indoor map milestone.*
