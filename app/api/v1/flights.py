"""Flight CRUD and search API."""

from datetime import date, datetime, time, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.airports import Airport
from app.models.flights import Flight
from app.schemas.airports import AirportRead
from app.schemas.flights import (
    FlightCreate,
    FlightDetailRead,
    FlightRead,
    FlightSearchResponse,
    FlightUpdate,
)

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
    """Create flight (admin)."""
    if data.origin_airport_id == data.destination_airport_id:
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
        flight_number=data.flight_number.strip(),
        origin_airport_id=data.origin_airport_id,
        destination_airport_id=data.destination_airport_id,
        departure_at=data.departure_at,
        arrival_at=data.arrival_at,
        base_price=data.base_price,
        total_seats=data.total_seats,
    )
    db.add(flight)
    await db.commit()
    await db.refresh(flight)
    return FlightRead.model_validate(flight)


@router.get(
    "/flights",
    response_model=list[FlightRead],
    dependencies=[Depends(require_permission("flights.manage"))],
)
async def list_flights_admin(
    db: AsyncSession = Depends(get_db),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> list[FlightRead]:
    """List flights (admin)."""
    result = await db.execute(
        select(Flight).order_by(Flight.departure_at.desc()).offset(skip).limit(limit),
    )
    rows = result.scalars().all()
    return [FlightRead.model_validate(f) for f in rows]


@router.get(
    "/flights/search",
    response_model=FlightSearchResponse,
    dependencies=[Depends(require_permission("flights.read"))],
)
async def search_flights(
    db: AsyncSession = Depends(get_db),
    departure_date: date | None = Query(None, description="Filter by departure local day (UTC window)"),
    destination_airport_id: int | None = Query(None),
    destination_iata: str | None = Query(None, min_length=3, max_length=3),
    origin_airport_id: int | None = Query(None),
    origin_iata: str | None = Query(None, min_length=3, max_length=3),
    max_price: float | None = Query(None, ge=0),
    sort: str = Query("departure_at"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
) -> FlightSearchResponse:
    """Search flights with filters, sort, pagination."""
    stmt = select(Flight)

    if departure_date is not None:
        start = datetime.combine(departure_date, time.min, tzinfo=timezone.utc)
        end = datetime.combine(departure_date, time.max, tzinfo=timezone.utc)
        stmt = stmt.where(Flight.departure_at >= start, Flight.departure_at <= end)

    if destination_airport_id is not None:
        stmt = stmt.where(Flight.destination_airport_id == destination_airport_id)
    elif destination_iata:
        dst_sq = select(Airport.id).where(Airport.iata_code == destination_iata.upper())
        stmt = stmt.where(Flight.destination_airport_id.in_(dst_sq))

    if origin_airport_id is not None:
        stmt = stmt.where(Flight.origin_airport_id == origin_airport_id)
    elif origin_iata:
        org_sq = select(Airport.id).where(Airport.iata_code == origin_iata.upper())
        stmt = stmt.where(Flight.origin_airport_id.in_(org_sq))

    if max_price is not None:
        stmt = stmt.where(Flight.base_price <= max_price)

    total = (await db.execute(select(func.count()).select_from(stmt.subquery()))).scalar_one()

    sort_key = sort.lstrip("-")
    desc = sort.startswith("-")
    if sort_key not in ("departure_at", "base_price"):
        sort_key = "departure_at"
        desc = False
    if sort_key == "base_price":
        order_col = Flight.base_price.desc() if desc else Flight.base_price.asc()
    else:
        order_col = Flight.departure_at.desc() if desc else Flight.departure_at.asc()
    stmt = stmt.order_by(order_col).offset(skip).limit(limit)

    result = await db.execute(stmt)
    rows = result.scalars().all()
    return FlightSearchResponse(
        items=[FlightRead.model_validate(f) for f in rows],
        total=total,
        skip=skip,
        limit=limit,
    )


@router.get(
    "/flights/{flight_id}",
    response_model=FlightDetailRead,
    dependencies=[Depends(require_permission("flights.read"))],
)
async def get_flight_detail(flight_id: int, db: AsyncSession = Depends(get_db)) -> FlightDetailRead:
    """Flight detail with airports."""
    result = await db.execute(
        select(Flight)
        .options(
            selectinload(Flight.origin_airport),
            selectinload(Flight.destination_airport),
        )
        .where(Flight.id == flight_id),
    )
    flight = result.scalar_one_or_none()
    if flight is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    base = FlightRead.model_validate(flight)
    return FlightDetailRead(
        **base.model_dump(),
        origin_airport=AirportRead.model_validate(flight.origin_airport),
        destination_airport=AirportRead.model_validate(flight.destination_airport),
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
    """Update flight."""
    result = await db.execute(select(Flight).where(Flight.id == flight_id))
    flight = result.scalar_one_or_none()
    if flight is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
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
    if data.total_seats is not None:
        flight.total_seats = data.total_seats
    if flight.departure_at >= flight.arrival_at:
        raise HTTPException(status_code=400, detail="Arrival must be after departure")
    if flight.origin_airport_id == flight.destination_airport_id:
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
