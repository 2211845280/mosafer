"""Flight CRUD and search API."""

import asyncio
import json

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import StreamingResponse
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.cache import RedisCache, get_cache
from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.flights import Flight
from app.schemas.flight_status import FlightStatusRead
from app.schemas.flights import (
    FlightCreate,
    FlightOfferRead,
    FlightRead,
    FlightSearchResponse,
    FlightUpdate,
)
from app.schemas.pagination import PaginatedResponse
from app.services.external.mock_flight_service import MockFlightService
from app.services.external.mock_flight_status_service import MockFlightStatusService

logger = structlog.get_logger(__name__)

_mock_service = MockFlightService()
_status_service = MockFlightStatusService()

router = APIRouter()


@router.post(
    "/flights",
    response_model=FlightRead,
    dependencies=[Depends(require_permission("flights.manage"))],
)
async def create_flight(
    data: FlightCreate,
    db: AsyncSession = Depends(get_db),
) -> FlightRead:
    """Create local stored flight (admin)."""
    if data.origin_airport_id is not None and data.origin_airport_id == data.destination_airport_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Origin and destination must differ",
        )
    if data.departure_at >= data.arrival_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Arrival must be after departure",
        )
    flight = Flight(
        provider_flight_id=data.provider_flight_id.strip(),
        origin_iata=data.origin_iata.upper(),
        destination_iata=data.destination_iata.upper(),
        carrier_code=data.carrier_code.upper(),
        flight_number=data.flight_number.strip(),
        origin_airport_id=data.origin_airport_id,
        destination_airport_id=data.destination_airport_id,
        departure_at=data.departure_at,
        arrival_at=data.arrival_at,
        base_price=data.base_price,
        currency=data.currency.upper() if data.currency else None,
        total_seats=data.total_seats,
    )
    db.add(flight)
    await db.commit()
    await db.refresh(flight)
    return FlightRead.model_validate(flight)


@router.get(
    "/flights",
    response_model=PaginatedResponse[FlightRead],
    dependencies=[Depends(require_permission("flights.manage"))],
)
async def list_flights_admin(
    db: AsyncSession = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
) -> PaginatedResponse[FlightRead]:
    """List locally stored flights (admin) with pagination."""
    total = (await db.execute(select(func.count()).select_from(Flight))).scalar_one()
    offset = (page - 1) * page_size
    result = await db.execute(
        select(Flight).order_by(Flight.departure_at.desc()).offset(offset).limit(page_size),
    )
    items = [FlightRead.model_validate(f) for f in result.scalars().all()]
    return PaginatedResponse.create(items=items, total=total, page=page, page_size=page_size)


@router.get(
    "/flights/search",
    response_model=FlightSearchResponse,
    dependencies=[Depends(require_permission("flights.read"))],
)
async def search_flights(
    origin_iata: str = Query(..., min_length=3, max_length=3),
    destination_iata: str = Query(..., min_length=3, max_length=3),
    departure_date: str = Query(..., description="YYYY-MM-DD"),
    adults: int = Query(1, ge=1, le=9),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    cache: RedisCache = Depends(get_cache),
) -> FlightSearchResponse:
    """Search flights via Mock Flight API (cached for 10 min)."""
    cache_key = (
        f"flights:search:{origin_iata.upper()}:{destination_iata.upper()}"
        f":{departure_date}:{adults}"
    )

    cached = await cache.get(cache_key)
    if cached is not None:
        logger.debug("flight_search.cache_hit", key=cache_key)
        all_offers = [FlightOfferRead(**item) for item in cached]
    else:
        all_offers = await _mock_service.search_flights(
            origin=origin_iata,
            destination=destination_iata,
            departure_date=departure_date,
            adults=adults,
        )
        await cache.set(
            cache_key,
            [o.model_dump(mode="json") for o in all_offers],
            ttl_seconds=600,
        )

    total = len(all_offers)
    page = all_offers[skip : skip + limit]
    return FlightSearchResponse(
        items=page,
        total=total,
        skip=skip,
        limit=limit,
    )


@router.get(
    "/flights/{flight_id}",
    response_model=FlightRead,
    dependencies=[Depends(require_permission("flights.read"))],
)
async def get_flight_detail(flight_id: int, db: AsyncSession = Depends(get_db)) -> FlightRead:
    """Get stored flight details by id."""
    result = await db.execute(select(Flight).where(Flight.id == flight_id))
    flight = result.scalar_one_or_none()
    if flight is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    return FlightRead.model_validate(flight)


@router.get(
    "/flights/{flight_id}/status",
    response_model=FlightStatusRead,
    dependencies=[Depends(require_permission("flights.read"))],
)
async def get_flight_status(
    flight_id: int,
    db: AsyncSession = Depends(get_db),
    cache: RedisCache = Depends(get_cache),
) -> FlightStatusRead:
    """Get real-time flight status (cached 2 min)."""
    cache_key = f"flight:status:{flight_id}"

    cached = await cache.get(cache_key)
    if cached is not None:
        logger.debug("flight_status.cache_hit", flight_id=flight_id)
        return FlightStatusRead(**cached)

    result = await db.execute(select(Flight).where(Flight.id == flight_id))
    flight = result.scalar_one_or_none()
    if flight is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")

    status_data = await _status_service.get_status(
        carrier_code=flight.carrier_code,
        flight_number=flight.flight_number,
        departure_at=flight.departure_at,
    )
    await cache.set(cache_key, status_data.model_dump(mode="json"), ttl_seconds=120)
    return status_data


@router.get(
    "/flights/{flight_id}/status/stream",
    dependencies=[Depends(require_permission("flights.read"))],
)
async def stream_flight_status(
    flight_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
    cache: RedisCache = Depends(get_cache),
) -> StreamingResponse:
    """SSE stream of flight status updates (polls Redis every 10 s, 2 h timeout)."""
    result = await db.execute(select(Flight).where(Flight.id == flight_id))
    flight = result.scalar_one_or_none()
    if flight is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")

    async def _event_generator():
        cache_key = f"flight:status:{flight_id}"
        last_payload: str | None = None
        max_seconds = 2 * 60 * 60
        elapsed = 0
        heartbeat_interval = 30
        poll_interval = 10
        ticks_since_heartbeat = 0

        while elapsed < max_seconds:
            if await request.is_disconnected():
                break

            raw = await cache.get(cache_key)
            if raw is not None:
                current_payload = json.dumps(raw, sort_keys=True)
                if current_payload != last_payload:
                    last_payload = current_payload
                    yield f"data: {json.dumps(raw)}\n\n"
                    ticks_since_heartbeat = 0

            ticks_since_heartbeat += poll_interval
            if ticks_since_heartbeat >= heartbeat_interval:
                yield ": keepalive\n\n"
                ticks_since_heartbeat = 0

            await asyncio.sleep(poll_interval)
            elapsed += poll_interval

    return StreamingResponse(
        _event_generator(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@router.patch(
    "/flights/{flight_id}",
    response_model=FlightRead,
    dependencies=[Depends(require_permission("flights.manage"))],
)
async def update_flight(
    flight_id: int,
    data: FlightUpdate,
    db: AsyncSession = Depends(get_db),
) -> FlightRead:
    """Update stored flight."""
    result = await db.execute(select(Flight).where(Flight.id == flight_id))
    flight = result.scalar_one_or_none()
    if flight is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    if data.provider_flight_id is not None:
        flight.provider_flight_id = data.provider_flight_id.strip()
    if data.origin_iata is not None:
        flight.origin_iata = data.origin_iata.upper()
    if data.destination_iata is not None:
        flight.destination_iata = data.destination_iata.upper()
    if data.carrier_code is not None:
        flight.carrier_code = data.carrier_code.upper()
    if data.flight_number is not None:
        flight.flight_number = data.flight_number.strip()
    if data.origin_airport_id is not None:
        flight.origin_airport_id = data.origin_airport_id
    if data.destination_airport_id is not None:
        flight.destination_airport_id = data.destination_airport_id
    if data.departure_at is not None:
        flight.departure_at = data.departure_at
    if data.arrival_at is not None:
        flight.arrival_at = data.arrival_at
    if data.base_price is not None:
        flight.base_price = data.base_price
    if data.currency is not None:
        flight.currency = data.currency.upper()
    if data.total_seats is not None:
        flight.total_seats = data.total_seats
    if flight.departure_at >= flight.arrival_at:
        raise HTTPException(status_code=400, detail="Arrival must be after departure")
    if (
        flight.origin_airport_id is not None
        and flight.destination_airport_id is not None
        and flight.origin_airport_id == flight.destination_airport_id
    ):
        raise HTTPException(status_code=400, detail="Origin and destination must differ")
    await db.commit()
    await db.refresh(flight)
    return FlightRead.model_validate(flight)


@router.delete(
    "/flights/{flight_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_permission("flights.manage"))],
)
async def delete_flight(flight_id: int, db: AsyncSession = Depends(get_db)) -> None:
    """Delete flight."""
    result = await db.execute(select(Flight).where(Flight.id == flight_id))
    flight = result.scalar_one_or_none()
    if flight is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    await db.delete(flight)
    await db.commit()
