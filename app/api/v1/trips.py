"""Trip-level endpoints: departure planner, location check, AI features."""

from __future__ import annotations

import math
from datetime import UTC, datetime, timedelta

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.cache import RedisCache, get_cache
from app.core.locale import resolve_request_locale
from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.airports import Airport
from app.models.flights import Flight
from app.models.reservations import Reservation
from app.models.trip_feedback import TripFeedback
from app.models.trip_todos import TripTodo
from app.models.user_preferences import UserPreference
from app.models.users import User
from app.schemas.ai import (
    DestinationTipsResult,
    PackingItem,
    PackingListResult,
    PackingWeatherContext,
    TimelineItem,
    TimelineResult,
    TripFeedbackCreate,
    TripFeedbackRead,
)
from app.schemas.departure_plan import (
    AirportContextRead,
    AirportDashboardResponse,
    ArrivalContextRead,
    BoardingCountdown,
    DeparturePlanResult,
    FlightStatusSummary,
    GateSuggestion,
    GateSuggestionLevel,
    LocationCheckRequest,
    LocationCheckResponse,
    TransportMode,
)
from app.schemas.indoor_map import IndoorMapBounds, IndoorMapResponse
from app.schemas.trip_todos import TripTodoCreate, TripTodoRead, TripTodoUpdate
from app.services.ai.packing_agent import generate_packing_list
from app.services.departure_planner import DeparturePlanner
from app.services.external.mock_flight_status_service import MockFlightStatusService
from app.services.external.openweather_service import get_destination_weather
from app.services.external.overpass_indoor_service import fetch_istanbul_indoor_map
from app.services.istanbul_indoor_highlights import apply_amenity_highlights

logger = structlog.get_logger(__name__)

router = APIRouter()

_REDUNDANT_BOOKED_TASK_PATTERNS = (
    "book flight",
    "book ticket",
    "book tickets",
    "book transport",
    "book transportation",
    "book taxi",
    "book airport taxi",
    "arrange transport",
    "arrange transportation",
    "reserve flight",
    "purchase ticket",
    "purchase tickets",
    "احجز تذكرة",
    "احجز تذاكر",
    "احجز تذاكر الطيران",
    "احجز وسيلة",
    "احجز مواصلات",
    "احجز النقل",
    "احجز أجرة",
    "ترتيب وسائل",
    "ترتيب النقل",
    "حجز تذاكر",
)

_TRANSPORT_TASK_PATTERNS = (
    "transport",
    "transportation",
    "taxi",
    "airport transfer",
    "وسيلة النقل",
    "وسائل النقل",
    "مواصلات",
    "أجرة",
    "نقل",
)


def _normalized_timeline_text(*parts: str) -> str:
    return " ".join(part.strip().lower() for part in parts if part and part.strip())


def _is_redundant_booked_trip_task(title: str, description: str = "") -> bool:
    normalized = _normalized_timeline_text(title, description)
    return any(pattern in normalized for pattern in _REDUNDANT_BOOKED_TASK_PATTERNS)


def _is_early_transport_task(item: TimelineItem) -> bool:
    if item.days_before <= 1:
        return False
    normalized = _normalized_timeline_text(item.title, item.description)
    return any(pattern in normalized for pattern in _TRANSPORT_TASK_PATTERNS)


def _default_timeline_items(locale: str) -> list[TimelineItem]:
    if locale == "ar":
        return [
            TimelineItem(
                days_before=14,
                title="التحقق من صلاحية جواز السفر",
                description="تأكد من صلاحية 6 أشهر على الأقل",
                category="document",
            ),
            TimelineItem(
                days_before=7,
                title="تأكيد بيانات الحجز",
                description="راجع تفاصيل الرحلة والمقعد في التطبيق",
                category="document",
            ),
            TimelineItem(
                days_before=7,
                title="بدء تجهيز الأساسيات",
                description="استخدم قائمة التجهيز الذكية",
                category="packing",
            ),
            TimelineItem(
                days_before=1,
                title="شحن الأجهزة",
                description="الهاتف، الحاسوب، بنك الطاقة",
                category="task",
            ),
            TimelineItem(
                days_before=1,
                title="مراجعة خطة المغادرة",
                description="تحقق من وقت المغادرة والمسار",
                category="task",
            ),
            TimelineItem(
                days_before=0,
                title="التوجه إلى المطار",
                description="راجع خطة المغادرة للتوقيت",
                category="task",
            ),
        ]
    return [
        TimelineItem(
            days_before=14,
            title="Check passport validity",
            description="Ensure 6+ months validity",
            category="document",
        ),
        TimelineItem(
            days_before=7,
            title="Confirm booking details",
            description="Review flight and seat details in the app",
            category="document",
        ),
        TimelineItem(
            days_before=7,
            title="Start packing essentials",
            description="Use the smart packing list",
            category="packing",
        ),
        TimelineItem(
            days_before=1,
            title="Charge devices",
            description="Phone, laptop, power bank",
            category="task",
        ),
        TimelineItem(
            days_before=1,
            title="Review departure plan",
            description="Check leave time and route",
            category="task",
        ),
        TimelineItem(
            days_before=0,
            title="Head to airport",
            description="Check departure plan for timing",
            category="task",
        ),
    ]


def _timeline_item_key(item: TimelineItem) -> str:
    return _normalized_timeline_text(item.title, item.category)


def _filter_timeline_items(items: list[TimelineItem], locale: str = "en") -> list[TimelineItem]:
    filtered = [
        item
        for item in items
        if not _is_redundant_booked_trip_task(item.title, item.description)
        and not _is_early_transport_task(item)
    ]
    existing = {_timeline_item_key(item) for item in filtered}
    for fallback in _default_timeline_items(locale):
        key = _timeline_item_key(fallback)
        if key not in existing:
            filtered.append(fallback)
            existing.add(key)
    filtered.sort(key=lambda item: item.days_before, reverse=True)
    return filtered

_planner = DeparturePlanner()
_status_service = MockFlightStatusService()

_EARTH_RADIUS_KM = 6371.0


def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    rlat1, rlng1, rlat2, rlng2 = (math.radians(v) for v in (lat1, lng1, lat2, lng2))
    dlat = rlat2 - rlat1
    dlng = rlng2 - rlng1
    a = math.sin(dlat / 2) ** 2 + math.cos(rlat1) * math.cos(rlat2) * math.sin(dlng / 2) ** 2
    return 2 * _EARTH_RADIUS_KM * math.asin(math.sqrt(a))


def _map_preferred_transport(value: str | None) -> TransportMode:
    normalized = (value or "").strip().lower()
    if normalized == "car":
        return TransportMode.driving
    if normalized in {"train", "bus"}:
        return TransportMode.transit
    if normalized == "taxi":
        return TransportMode.taxi
    return TransportMode.driving


async def _load_reservation_with_flight_and_airport(
    reservation_id: int,
    user: User,
    db: AsyncSession,
) -> tuple[Reservation, Flight, Airport]:
    """Load reservation and validate ownership. Returns (reservation, flight, airport)."""
    result = await db.execute(
        select(Reservation)
        .where(Reservation.id == reservation_id)
        .options(selectinload(Reservation.flight))
    )
    reservation = result.scalar_one_or_none()
    if reservation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found")
    if reservation.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your reservation")

    flight = reservation.flight

    airport_result = await db.execute(
        select(Airport).where(Airport.iata_code == flight.origin_iata)
    )
    airport = airport_result.scalar_one_or_none()
    if airport is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Origin airport {flight.origin_iata} not found in database",
        )
    if airport.latitude is None or airport.longitude is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Airport {flight.origin_iata} is missing coordinates",
        )

    return reservation, flight, airport


def _build_gate_suggestion(minutes_to_boarding: int) -> GateSuggestion:
    if minutes_to_boarding > 60:
        return GateSuggestion(
            level=GateSuggestionLevel.explore,
            message="You have time to explore terminal shops and restaurants.",
        )
    if minutes_to_boarding >= 30:
        return GateSuggestion(
            level=GateSuggestionLevel.move_near_gate,
            message="Head toward your gate area and grab food nearby.",
        )
    return GateSuggestion(
        level=GateSuggestionLevel.proceed_now,
        message="Proceed to your gate now.",
    )


def _estimate_walking_time_to_gate(departure_gate: str | None) -> int:
    """Simple mock estimate based on gate number."""
    if not departure_gate:
        return 8
    digits = "".join(ch for ch in departure_gate if ch.isdigit())
    gate_num = int(digits) if digits else 10
    return max(4, min(18, 4 + gate_num // 2))


def _extract_nearby_food_shops(amenities: dict | None) -> list[str]:
    if not amenities:
        return ["Coffee Point", "Quick Bites", "Travel Essentials"]
    for key in ("restaurants", "food", "shops", "dining"):
        value = amenities.get(key)
        if isinstance(value, list):
            items = [str(v) for v in value if v]
            if items:
                return items[:6]
    return ["Coffee Point", "Quick Bites", "Travel Essentials"]


def _build_boarding_countdown(
    departure_at: datetime,
    delay_minutes: int,
) -> BoardingCountdown:
    now = datetime.now(UTC)
    adjusted_departure = departure_at + timedelta(minutes=delay_minutes)
    boarding_at = adjusted_departure - timedelta(minutes=30)
    minutes_to_boarding = max(0, int((boarding_at - now).total_seconds() / 60))
    return BoardingCountdown(
        boarding_at=boarding_at,
        minutes_to_boarding=minutes_to_boarding,
        is_boarding_open=minutes_to_boarding == 0,
    )


async def _get_destination_tips(
    iata: str,
    airport: Airport | None,
    cache: RedisCache,
) -> DestinationTipsResult:
    iata_upper = iata.upper()
    cache_key = f"destination_tips:{iata_upper}"
    cached = await cache.get(cache_key)
    if cached is not None:
        return DestinationTipsResult(**cached)

    if airport is None:
        return DestinationTipsResult(
            general_tips=[f"Research destination {iata_upper} before arrival."],
        )

    from app.services.ai.prompts.destination_tips import build_tips_prompt

    system_prompt, user_message = build_tips_prompt(
        city=airport.city,
        country=airport.country,
        iata=iata_upper,
    )

    try:
        from app.services.ai.llm_client import get_llm_client

        client = get_llm_client()
        data = await client.chat_json(system_prompt, user_message)
        tips = DestinationTipsResult(**data)
    except Exception:
        logger.exception("airport_dashboard.destination_tips_fallback", iata=iata_upper)
        tips = DestinationTipsResult(
            visa=f"Check visa requirements for {airport.country}.",
            currency=f"Local currency used in {airport.country}.",
            language=f"Official language of {airport.country}.",
            general_tips=[f"Review arrival information for {airport.city}."],
        )

    await cache.set(cache_key, tips.model_dump(mode="json"), ttl_seconds=604800)
    return tips


# ---------------------------------------------------------------------------
# 4.4 — Departure Plan
# ---------------------------------------------------------------------------


@router.get(
    "/trips/{reservation_id}/departure-plan",
    response_model=DeparturePlanResult,
)
async def get_departure_plan(
    reservation_id: int,
    lat: float | None = Query(None, ge=-90, le=90, description="User latitude"),
    lng: float | None = Query(None, ge=-180, le=180, description="User longitude"),
    mode: TransportMode | None = Query(None, description="Transport mode override"),
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
    cache: RedisCache = Depends(get_cache),
) -> DeparturePlanResult:
    """Recommend when to leave for the airport."""
    reservation, flight, airport = await _load_reservation_with_flight_and_airport(
        reservation_id, user, db,
    )

    if lat is None or lng is None:
        pref_result = await db.execute(
            select(UserPreference).where(UserPreference.user_id == user.id)
        )
        pref = pref_result.scalar_one_or_none()
        if pref and pref.home_lat is not None and pref.home_lng is not None:
            lat = float(pref.home_lat)
            lng = float(pref.home_lng)
        else:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Provide lat/lng query params or set home location in preferences",
            )

    if mode is None:
        pref_result2 = await db.execute(
            select(UserPreference).where(UserPreference.user_id == user.id)
        )
        pref2 = pref_result2.scalar_one_or_none()
        mode = _map_preferred_transport(pref2.preferred_transport if pref2 else None)

    cache_key = f"departure_plan:{reservation_id}:{round(lat, 4)}:{round(lng, 4)}:{mode.value}"
    cached = await cache.get(cache_key)
    if cached is not None:
        logger.debug("departure_plan.cache_hit", key=cache_key)
        return DeparturePlanResult(**cached)

    dest_airport_result = await db.execute(
        select(Airport).where(Airport.iata_code == flight.destination_iata)
    )
    dest_airport = dest_airport_result.scalar_one_or_none()
    dest_country = dest_airport.country if dest_airport else "Unknown"

    plan = await _planner.calculate(
        user_lat=lat,
        user_lng=lng,
        airport_lat=float(airport.latitude),
        airport_lng=float(airport.longitude),
        airport_country=dest_country,
        origin_country=airport.country,
        departure_at=flight.departure_at,
        transport_mode=mode,
        destination_airport_lat=(
            float(dest_airport.latitude) if dest_airport and dest_airport.latitude else None
        ),
        destination_airport_lng=(
            float(dest_airport.longitude) if dest_airport and dest_airport.longitude else None
        ),
        arrival_at=flight.arrival_at,
    )

    await cache.set(cache_key, plan.model_dump(mode="json"), ttl_seconds=300)
    return plan


# ---------------------------------------------------------------------------
# 4.6 — Location Check ("At Airport" trigger)
# ---------------------------------------------------------------------------


@router.post(
    "/trips/{reservation_id}/location-check",
    response_model=LocationCheckResponse,
)
async def location_check(
    reservation_id: int,
    body: LocationCheckRequest,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
    cache: RedisCache = Depends(get_cache),
) -> LocationCheckResponse:
    """Check if user is at the airport; return in-airport context or departure plan."""
    reservation, flight, airport = await _load_reservation_with_flight_and_airport(
        reservation_id, user, db,
    )

    distance = round(
        _haversine(body.lat, body.lng, float(airport.latitude), float(airport.longitude)),
        2,
    )

    if distance <= 1.0:
        status_cache_key = f"flight:status:{flight.id}"
        cached_status = await cache.get(status_cache_key)

        if cached_status is not None:
            flight_status = FlightStatusSummary(**cached_status)
        else:
            fresh = await _status_service.get_status(
                carrier_code=flight.carrier_code,
                flight_number=flight.flight_number,
                departure_at=flight.departure_at,
                origin_iata=flight.origin_iata,
            )
            flight_status = FlightStatusSummary(
                flight_number=fresh.flight_number,
                carrier_code=fresh.carrier_code,
                departure_gate=fresh.departure_gate,
                terminal=fresh.terminal,
                status=fresh.status.value,
                delay_minutes=fresh.delay_minutes,
            )
            await cache.set(
                status_cache_key,
                fresh.model_dump(mode="json"),
                ttl_seconds=120,
            )

        adjusted_departure = flight.departure_at + timedelta(minutes=flight_status.delay_minutes)
        boarding_time = adjusted_departure - timedelta(minutes=30)
        now = datetime.now(UTC)
        minutes_to_boarding = max(0, int((boarding_time - now).total_seconds() / 60))

        airport_ctx = AirportContextRead(
            iata_code=airport.iata_code,
            name=airport.name,
            terminal_info=airport.terminal_info,
            amenities=airport.amenities,
            map_url=airport.map_url,
        )

        return LocationCheckResponse(
            at_airport=True,
            distance_km=distance,
            flight_status=flight_status,
            airport=airport_ctx,
            minutes_to_boarding=minutes_to_boarding,
        )

    pref_result = await db.execute(
        select(UserPreference).where(UserPreference.user_id == user.id)
    )
    pref = pref_result.scalar_one_or_none()
    transport = _map_preferred_transport(pref.preferred_transport if pref else None)

    dest_airport_result = await db.execute(
        select(Airport).where(Airport.iata_code == flight.destination_iata)
    )
    dest_airport = dest_airport_result.scalar_one_or_none()
    dest_country = dest_airport.country if dest_airport else "Unknown"

    plan = await _planner.calculate(
        user_lat=body.lat,
        user_lng=body.lng,
        airport_lat=float(airport.latitude),
        airport_lng=float(airport.longitude),
        airport_country=dest_country,
        origin_country=airport.country,
        departure_at=flight.departure_at,
        transport_mode=transport,
        destination_airport_lat=(
            float(dest_airport.latitude) if dest_airport and dest_airport.latitude else None
        ),
        destination_airport_lng=(
            float(dest_airport.longitude) if dest_airport and dest_airport.longitude else None
        ),
        arrival_at=flight.arrival_at,
    )

    return LocationCheckResponse(
        at_airport=False,
        distance_km=distance,
        departure_plan=plan,
    )


@router.get(
    "/trips/{reservation_id}/airport-dashboard",
    response_model=AirportDashboardResponse,
)
async def get_airport_dashboard(
    reservation_id: int,
    lat: float = Query(..., ge=-90, le=90, description="Current user latitude"),
    lng: float = Query(..., ge=-180, le=180, description="Current user longitude"),
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
    cache: RedisCache = Depends(get_cache),
) -> AirportDashboardResponse:
    """Airport live dashboard for in-terminal experience."""
    _, flight, origin_airport = await _load_reservation_with_flight_and_airport(
        reservation_id, user, db,
    )

    distance = round(
        _haversine(lat, lng, float(origin_airport.latitude), float(origin_airport.longitude)),
        2,
    )
    at_airport = distance <= 1.0

    status_cache_key = f"flight:status:{flight.id}"
    cached_status = await cache.get(status_cache_key)
    if cached_status is not None:
        flight_status = FlightStatusSummary(**cached_status)
    else:
        fresh = await _status_service.get_status(
            carrier_code=flight.carrier_code,
            flight_number=flight.flight_number,
            departure_at=flight.departure_at,
            origin_iata=flight.origin_iata,
        )
        flight_status = FlightStatusSummary(
            flight_number=fresh.flight_number,
            carrier_code=fresh.carrier_code,
            departure_gate=fresh.departure_gate,
            terminal=fresh.terminal,
            status=fresh.status.value,
            delay_minutes=fresh.delay_minutes,
        )
        await cache.set(
            status_cache_key,
            fresh.model_dump(mode="json"),
            ttl_seconds=120,
        )

    boarding = _build_boarding_countdown(flight.departure_at, flight_status.delay_minutes)
    gate_suggestion = _build_gate_suggestion(boarding.minutes_to_boarding)
    walking_time = _estimate_walking_time_to_gate(flight_status.departure_gate)
    nearby = _extract_nearby_food_shops(origin_airport.amenities)

    airport_ctx = AirportContextRead(
        iata_code=origin_airport.iata_code,
        name=origin_airport.name,
        terminal_info=origin_airport.terminal_info,
        amenities=origin_airport.amenities,
        map_url=origin_airport.map_url,
    )

    arrival_context: ArrivalContextRead | None = None
    if flight_status.status == "landed":
        dest_result = await db.execute(
            select(Airport).where(Airport.iata_code == flight.destination_iata)
        )
        destination_airport = dest_result.scalar_one_or_none()
        if destination_airport is not None:
            dest_ctx = AirportContextRead(
                iata_code=destination_airport.iata_code,
                name=destination_airport.name,
                terminal_info=destination_airport.terminal_info,
                amenities=destination_airport.amenities,
                map_url=destination_airport.map_url,
            )
            tips = await _get_destination_tips(
                iata=destination_airport.iata_code,
                airport=destination_airport,
                cache=cache,
            )

            local_transport = []
            for key in ("transport", "local_transport", "ground_transport"):
                value = (destination_airport.amenities or {}).get(key)
                if isinstance(value, list):
                    local_transport = [str(v) for v in value if v][:6]
                    break
            if not local_transport:
                local_transport = ["Taxi", "Airport bus", "Car rental"]

            arrival_context = ArrivalContextRead(
                airport=dest_ctx,
                immigration_tip="Keep passport and arrival form ready before immigration queue.",
                baggage_claim=f"Belt {((flight.id % 12) + 1)}",
                local_transport_options=local_transport,
                destination_tips=tips.general_tips[:5],
            )

    return AirportDashboardResponse(
        reservation_id=reservation_id,
        at_airport=at_airport,
        distance_km=distance,
        flight_status=flight_status,
        airport=airport_ctx,
        boarding=boarding,
        walking_time_to_gate_minutes=walking_time,
        nearby_food_shops=nearby,
        gate_suggestion=gate_suggestion,
        arrival_context=arrival_context,
    )


@router.get(
    "/trips/{reservation_id}/airport-indoor-map",
    response_model=IndoorMapResponse,
)
async def get_airport_indoor_map(
    reservation_id: int,
    gate: str | None = Query(None, description="Gate to highlight, e.g. G12"),
    highlight: str | None = Query(
        None,
        description="Amenity category to highlight near gate: coffee | food",
    ),
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
    cache: RedisCache = Depends(get_cache),
) -> IndoorMapResponse:
    """Native indoor map for supported airports (IST only for now)."""
    _, flight, origin_airport = await _load_reservation_with_flight_and_airport(
        reservation_id, user, db,
    )

    iata = origin_airport.iata_code.upper()
    if iata != "IST":
        return IndoorMapResponse(
            airport_iata=iata,
            airport_name=origin_airport.name,
            default_level="0",
            levels=[],
            bounds=IndoorMapBounds(),
            features=[],
            pois=[],
            source="unsupported",
            is_fallback=True,
            supported=False,
            message=f"Indoor map is only available for Istanbul Airport (IST). Origin is {iata}.",
            highlight_gate=gate,
        )

    cache_key = f"indoor_map:IST:{gate or 'none'}:{highlight or 'none'}"
    cached = None
    try:
        cached = await cache.get(cache_key)
    except Exception as exc:
        logger.warning("indoor_map.cache_get_failed", key=cache_key, error=str(exc))

    if cached is not None:
        logger.debug("indoor_map.cache_hit", key=cache_key)
        return IndoorMapResponse(**cached)

    highlight_gate = gate or None
    if highlight_gate is None:
        status_cache_key = f"flight:status:{flight.id}"
        try:
            cached_status = await cache.get(status_cache_key)
            if cached_status and cached_status.get("departure_gate"):
                highlight_gate = str(cached_status["departure_gate"])
        except Exception as exc:
            logger.warning(
                "indoor_map.status_cache_get_failed",
                key=status_cache_key,
                error=str(exc),
            )

    result = await fetch_istanbul_indoor_map(highlight_gate=highlight_gate)
    result = apply_amenity_highlights(
        result,
        gate=highlight_gate,
        category=highlight,
    )
    from app.services.istanbul_indoor_geo import enrich_indoor_map

    result = enrich_indoor_map(result, gate=highlight_gate)
    try:
        await cache.set(cache_key, result.model_dump(mode="json"), ttl_seconds=86400)
    except Exception as exc:
        logger.warning("indoor_map.cache_set_failed", key=cache_key, error=str(exc))
    return result


async def _load_reservation_with_flight(
    reservation_id: int,
    user: User,
    db: AsyncSession,
) -> tuple[Reservation, Flight]:
    """Load reservation (ownership-checked) and its flight."""
    result = await db.execute(
        select(Reservation)
        .where(Reservation.id == reservation_id)
        .options(selectinload(Reservation.flight))
    )
    reservation = result.scalar_one_or_none()
    if reservation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found")
    if reservation.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your reservation")
    return reservation, reservation.flight


# ---------------------------------------------------------------------------
# 5.4 — Packing List
# ---------------------------------------------------------------------------


async def _build_packing_weather(
    dest_airport: Airport | None,
    dest_city: str,
    duration_days: int,
    departure_at: datetime,
) -> PackingWeatherContext | None:
    if (
        dest_airport is None
        or dest_airport.latitude is None
        or dest_airport.longitude is None
    ):
        return None

    weather = await get_destination_weather(
        float(dest_airport.latitude),
        float(dest_airport.longitude),
        departure_at,
    )
    return PackingWeatherContext(
        destination_city=dest_city,
        trip_duration_days=duration_days,
        condition=weather.condition,
        temperature_c=weather.temperature_c,
    )


def _merge_bilingual_packing_items(
    ar_items: list[PackingItem],
    en_items: list[PackingItem],
    section: str,
) -> list[PackingItem]:
    merged: list[PackingItem] = []
    for index in range(max(len(ar_items), len(en_items))):
        ar_item = ar_items[index] if index < len(ar_items) else None
        en_item = en_items[index] if index < len(en_items) else None
        title_ar = ar_item.title if ar_item else (en_item.title if en_item else "")
        title_en = en_item.title if en_item else (ar_item.title if ar_item else "")
        note_ar = ar_item.note if ar_item else (en_item.note if en_item else "")
        note_en = en_item.note if en_item else (ar_item.note if ar_item else "")
        title = title_en or title_ar
        if not title.strip():
            continue
        merged.append(
            PackingItem(
                key=f"{section}:{index}",
                title=title,
                note=note_en or note_ar,
                title_ar=title_ar,
                title_en=title_en,
                note_ar=note_ar,
                note_en=note_en,
            )
        )
    return merged


def _merge_bilingual_packing_lists(
    ar_list: PackingListResult,
    en_list: PackingListResult,
    weather: PackingWeatherContext | None = None,
) -> PackingListResult:
    return PackingListResult(
        must_have=_merge_bilingual_packing_items(
            ar_list.must_have,
            en_list.must_have,
            "must",
        ),
        recommended=_merge_bilingual_packing_items(
            ar_list.recommended,
            en_list.recommended,
            "rec",
        ),
        optional=_merge_bilingual_packing_items(
            ar_list.optional,
            en_list.optional,
            "opt",
        ),
        weather=weather,
    )


def _localized_packing_item(item: PackingItem, locale: str) -> PackingItem:
    wants_ar = locale == "ar"
    title = (
        item.title_ar if wants_ar and item.title_ar else item.title_en or item.title
    )
    note = item.note_ar if wants_ar and item.note_ar else item.note_en or item.note
    return item.model_copy(update={"title": title, "note": note})


def _localized_packing_list(
    packing: PackingListResult,
    locale: str,
) -> PackingListResult:
    return PackingListResult(
        must_have=[_localized_packing_item(item, locale) for item in packing.must_have],
        recommended=[
            _localized_packing_item(item, locale) for item in packing.recommended
        ],
        optional=[_localized_packing_item(item, locale) for item in packing.optional],
        weather=packing.weather,
    )


@router.post(
    "/trips/{reservation_id}/packing-list",
    response_model=PackingListResult,
)
async def get_packing_list(
    reservation_id: int,
    request: Request,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
    cache: RedisCache = Depends(get_cache),
) -> PackingListResult:
    """Generate an AI packing list for a trip (cached 24 h)."""
    locale = resolve_request_locale(request.headers.get("accept-language"))
    reservation, flight = await _load_reservation_with_flight(reservation_id, user, db)

    cache_key = f"packing_list:{reservation_id}:bilingual"
    cached = await cache.get(cache_key)
    if cached is not None:
        logger.debug("packing_list.cache_hit", key=cache_key)
        return _localized_packing_list(PackingListResult(**cached), locale)

    dest_result = await db.execute(
        select(Airport).where(Airport.iata_code == flight.destination_iata)
    )
    dest_airport = dest_result.scalar_one_or_none()

    origin_result = await db.execute(
        select(Airport).where(Airport.iata_code == flight.origin_iata)
    )
    origin_airport = origin_result.scalar_one_or_none()

    dest_city = dest_airport.city if dest_airport else flight.destination_iata
    dest_country = dest_airport.country if dest_airport else "Unknown"
    origin_country = origin_airport.country if origin_airport else "Unknown"
    dest_lat = float(dest_airport.latitude) if dest_airport and dest_airport.latitude else 0.0

    duration_days = max(1, (flight.arrival_at - flight.departure_at).days or 1)
    travel_dates = f"{flight.departure_at.strftime('%Y-%m-%d')} to {flight.arrival_at.strftime('%Y-%m-%d')}"

    result_ar = await generate_packing_list(
        destination_city=dest_city,
        destination_country=dest_country,
        origin_country=origin_country,
        trip_duration_days=duration_days,
        travel_dates=travel_dates,
        destination_latitude=dest_lat,
        departure_month=flight.departure_at.month,
        locale="ar",
    )
    result_en = await generate_packing_list(
        destination_city=dest_city,
        destination_country=dest_country,
        origin_country=origin_country,
        trip_duration_days=duration_days,
        travel_dates=travel_dates,
        destination_latitude=dest_lat,
        departure_month=flight.departure_at.month,
        locale="en",
    )
    weather = await _build_packing_weather(
        dest_airport,
        dest_city,
        duration_days,
        flight.departure_at,
    )
    result = _merge_bilingual_packing_lists(result_ar, result_en, weather)

    await cache.set(cache_key, result.model_dump(mode="json"), ttl_seconds=86400)
    return _localized_packing_list(result, locale)


# ---------------------------------------------------------------------------
# 5.7 — Trip Todo CRUD
# ---------------------------------------------------------------------------


@router.get(
    "/trips/{reservation_id}/todos",
    response_model=list[TripTodoRead],
)
async def list_trip_todos(
    reservation_id: int,
    category: str | None = Query(None),
    completed: bool | None = Query(None),
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
) -> list[TripTodoRead]:
    """List todos for a trip."""
    reservation, _ = await _load_reservation_with_flight(reservation_id, user, db)

    stmt = select(TripTodo).where(TripTodo.reservation_id == reservation.id)
    if category is not None:
        stmt = stmt.where(TripTodo.category == category)
    if completed is not None:
        stmt = stmt.where(TripTodo.is_completed == completed)
    stmt = stmt.order_by(TripTodo.due_date.asc().nulls_last(), TripTodo.id)

    result = await db.execute(stmt)
    return [TripTodoRead.model_validate(t) for t in result.scalars().all()]


@router.post(
    "/trips/{reservation_id}/todos",
    response_model=TripTodoRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_trip_todo(
    reservation_id: int,
    body: TripTodoCreate,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
) -> TripTodoRead:
    """Create a manual todo item for a trip."""
    reservation, _ = await _load_reservation_with_flight(reservation_id, user, db)

    todo = TripTodo(
        reservation_id=reservation.id,
        user_id=user.id,
        category=body.category,
        title=body.title,
        source_key=body.source_key,
        title_ar=body.title_ar,
        title_en=body.title_en,
        priority=body.priority,
        due_date=body.due_date,
        source="ai" if body.category == "packing" and body.source_key else "user",
    )
    db.add(todo)
    await db.commit()
    await db.refresh(todo)
    return TripTodoRead.model_validate(todo)


@router.patch(
    "/trips/{reservation_id}/todos/{todo_id}",
    response_model=TripTodoRead,
)
async def update_trip_todo(
    reservation_id: int,
    todo_id: int,
    body: TripTodoUpdate,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
) -> TripTodoRead:
    """Update a trip todo item."""
    await _load_reservation_with_flight(reservation_id, user, db)

    result = await db.execute(
        select(TripTodo).where(
            TripTodo.id == todo_id,
            TripTodo.reservation_id == reservation_id,
        )
    )
    todo = result.scalar_one_or_none()
    if todo is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Todo not found")

    if body.title is not None:
        todo.title = body.title
    if body.source_key is not None:
        todo.source_key = body.source_key
    if body.title_ar is not None:
        todo.title_ar = body.title_ar
    if body.title_en is not None:
        todo.title_en = body.title_en
    if body.category is not None:
        todo.category = body.category
    if body.priority is not None:
        todo.priority = body.priority
    if body.is_completed is not None:
        todo.is_completed = body.is_completed
    if body.due_date is not None:
        todo.due_date = body.due_date

    await db.commit()
    await db.refresh(todo)
    return TripTodoRead.model_validate(todo)


@router.delete(
    "/trips/{reservation_id}/todos/{todo_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_trip_todo(
    reservation_id: int,
    todo_id: int,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Delete a trip todo item."""
    await _load_reservation_with_flight(reservation_id, user, db)

    result = await db.execute(
        select(TripTodo).where(
            TripTodo.id == todo_id,
            TripTodo.reservation_id == reservation_id,
        )
    )
    todo = result.scalar_one_or_none()
    if todo is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Todo not found")
    await db.delete(todo)
    await db.commit()


@router.post(
    "/trips/{reservation_id}/todos/populate",
    response_model=list[TripTodoRead],
    status_code=status.HTTP_201_CREATED,
)
async def populate_todos_from_packing_list(
    reservation_id: int,
    request: Request,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
    cache: RedisCache = Depends(get_cache),
) -> list[TripTodoRead]:
    """Auto-populate trip todos from the AI packing list."""
    locale = resolve_request_locale(request.headers.get("accept-language"))
    reservation, flight = await _load_reservation_with_flight(reservation_id, user, db)

    cache_key = f"packing_list:{reservation_id}:bilingual"
    cached = await cache.get(cache_key)

    if cached is not None:
        packing = PackingListResult(**cached)
    else:
        dest_result = await db.execute(
            select(Airport).where(Airport.iata_code == flight.destination_iata)
        )
        dest_airport = dest_result.scalar_one_or_none()
        origin_result = await db.execute(
            select(Airport).where(Airport.iata_code == flight.origin_iata)
        )
        origin_airport = origin_result.scalar_one_or_none()

        dest_city = dest_airport.city if dest_airport else flight.destination_iata
        dest_country = dest_airport.country if dest_airport else "Unknown"
        origin_country = origin_airport.country if origin_airport else "Unknown"
        dest_lat = float(dest_airport.latitude) if dest_airport and dest_airport.latitude else 0.0
        duration_days = max(1, (flight.arrival_at - flight.departure_at).days or 1)
        travel_dates = f"{flight.departure_at.strftime('%Y-%m-%d')} to {flight.arrival_at.strftime('%Y-%m-%d')}"

        packing_ar = await generate_packing_list(
            destination_city=dest_city,
            destination_country=dest_country,
            origin_country=origin_country,
            trip_duration_days=duration_days,
            travel_dates=travel_dates,
            destination_latitude=dest_lat,
            departure_month=flight.departure_at.month,
            locale="ar",
        )
        packing_en = await generate_packing_list(
            destination_city=dest_city,
            destination_country=dest_country,
            origin_country=origin_country,
            trip_duration_days=duration_days,
            travel_dates=travel_dates,
            destination_latitude=dest_lat,
            departure_month=flight.departure_at.month,
            locale="en",
        )
        weather = await _build_packing_weather(
            dest_airport,
            dest_city,
            duration_days,
            flight.departure_at,
        )
        packing = _merge_bilingual_packing_lists(packing_ar, packing_en, weather)
        await cache.set(cache_key, packing.model_dump(mode="json"), ttl_seconds=86400)

    created: list[TripTodo] = []
    priority_map = {"must_have": "must", "recommended": "recommended", "optional": "optional"}
    for priority_key, items in [
        ("must_have", packing.must_have),
        ("recommended", packing.recommended),
        ("optional", packing.optional),
    ]:
        for item in items:
            todo = TripTodo(
                reservation_id=reservation.id,
                user_id=user.id,
                category="packing",
                title=_localized_packing_item(item, locale).title,
                source_key=item.key,
                title_ar=item.title_ar,
                title_en=item.title_en,
                priority=priority_map[priority_key],
                source="ai",
            )
            db.add(todo)
            created.append(todo)

    await db.commit()
    for t in created:
        await db.refresh(t)
    return [TripTodoRead.model_validate(t) for t in created]


# ---------------------------------------------------------------------------
# 5.8 — AI Timeline
# ---------------------------------------------------------------------------


@router.post(
    "/trips/{reservation_id}/timeline",
    response_model=TimelineResult,
)
async def generate_timeline(
    reservation_id: int,
    request: Request,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
    cache: RedisCache = Depends(get_cache),
) -> TimelineResult:
    """Generate an AI pre-trip preparation timeline and create todo records."""
    locale = resolve_request_locale(request.headers.get("accept-language"))
    reservation, flight = await _load_reservation_with_flight(reservation_id, user, db)

    cache_key = f"trip_timeline:{reservation_id}:{locale}"
    cached = await cache.get(cache_key)
    if cached is not None:
        logger.debug("timeline.cache_hit", key=cache_key)
        cached_result = TimelineResult(**cached)
        filtered_items = _filter_timeline_items(cached_result.items, locale=locale)
        return TimelineResult(items=filtered_items)

    dest_result = await db.execute(
        select(Airport).where(Airport.iata_code == flight.destination_iata)
    )
    dest_airport = dest_result.scalar_one_or_none()
    origin_result = await db.execute(
        select(Airport).where(Airport.iata_code == flight.origin_iata)
    )
    origin_airport = origin_result.scalar_one_or_none()

    dest_city = dest_airport.city if dest_airport else flight.destination_iata
    dest_country = dest_airport.country if dest_airport else "Unknown"
    origin_country = origin_airport.country if origin_airport else "Unknown"
    duration_days = max(1, (flight.arrival_at - flight.departure_at).days or 1)

    from app.services.ai.prompts.timeline import build_timeline_prompt

    system_prompt, user_message = build_timeline_prompt(
        destination_city=dest_city,
        destination_country=dest_country,
        origin_country=origin_country,
        departure_date=flight.departure_at.strftime("%Y-%m-%d"),
        trip_duration_days=duration_days,
        locale=locale,
    )

    try:
        from app.services.ai.llm_client import get_llm_client

        client = get_llm_client()
        data = await client.chat_json(system_prompt, user_message)
        raw_items = data.get("items", [])
        items = [TimelineItem(**i) for i in raw_items]
    except Exception:
        logger.exception("timeline.llm_failed, using defaults")
        items = _default_timeline_items(locale)

    items = _filter_timeline_items(items, locale=locale)

    timeline = TimelineResult(items=items)

    await cache.set(cache_key, timeline.model_dump(mode="json"), ttl_seconds=86400)
    return timeline


# ---------------------------------------------------------------------------
# 5.9 — Trip Feedback
# ---------------------------------------------------------------------------


@router.post(
    "/trips/{reservation_id}/feedback",
    response_model=TripFeedbackRead,
    status_code=status.HTTP_201_CREATED,
)
async def submit_feedback(
    reservation_id: int,
    body: TripFeedbackCreate,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
) -> TripFeedbackRead:
    """Submit post-trip feedback."""
    reservation, _ = await _load_reservation_with_flight(reservation_id, user, db)

    existing = await db.execute(
        select(TripFeedback).where(
            TripFeedback.reservation_id == reservation.id,
            TripFeedback.user_id == user.id,
        )
    )
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Feedback already submitted for this trip",
        )

    feedback = TripFeedback(
        reservation_id=reservation.id,
        user_id=user.id,
        rating=body.rating,
        packing_helpful=body.packing_helpful,
        missing_items=body.missing_items,
        comments=body.comments,
    )
    db.add(feedback)
    await db.commit()
    await db.refresh(feedback)
    return TripFeedbackRead.model_validate(feedback)


@router.get(
    "/trips/{reservation_id}/feedback",
    response_model=TripFeedbackRead,
)
async def get_feedback(
    reservation_id: int,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
) -> TripFeedbackRead:
    """Read feedback for a trip."""
    reservation, _ = await _load_reservation_with_flight(reservation_id, user, db)

    result = await db.execute(
        select(TripFeedback).where(
            TripFeedback.reservation_id == reservation.id,
            TripFeedback.user_id == user.id,
        )
    )
    feedback = result.scalar_one_or_none()
    if feedback is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No feedback found")
    return TripFeedbackRead.model_validate(feedback)
