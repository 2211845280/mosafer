"""Flight CRUD and Amadeus-backed search API."""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.flights import Flight
from app.schemas.flights import FlightCreate, FlightRead, FlightSearchResponse, FlightUpdate
from app.services.amadeus_service import AmadeusService

router = APIRouter()
amadeus_service = AmadeusService()


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
        amadeus_flight_id=data.amadeus_flight_id.strip(),
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
    response_model=list[FlightRead],
    dependencies=[Depends(require_permission("flights.manage"))],
)
async def list_flights_admin(
    db: AsyncSession = Depends(get_db),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> list[FlightRead]:
    """List locally stored flights (admin)."""
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
    origin_iata: str = Query(..., min_length=3, max_length=3),
    destination_iata: str = Query(..., min_length=3, max_length=3),
    departure_date: str = Query(..., description="YYYY-MM-DD"),
    adults: int = Query(1, ge=1, le=9),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
) -> FlightSearchResponse:
    """Search flights from Amadeus with pagination."""
    try:
        rows = await amadeus_service.search_flights(
            origin_iata=origin_iata,
            destination_iata=destination_iata,
            departure_date=departure_date,
            adults=adults,
            limit=limit + skip,
        )
    except Exception as exc:  # pragma: no cover - external API availability
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Amadeus search failed: {exc}",
        ) from exc
    sliced = rows[skip : skip + limit]
    return FlightSearchResponse(
        items=sliced,
        total=len(rows),
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
    if data.amadeus_flight_id is not None:
        flight.amadeus_flight_id = data.amadeus_flight_id.strip()
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
