"""Airport CRUD API."""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.airports import Airport
from app.schemas.airports import AirportCreate, AirportDetailRead, AirportRead, AirportUpdate
from app.schemas.pagination import PaginatedResponse

router = APIRouter()


@router.post(
    "/airports",
    response_model=AirportRead,
    dependencies=[Depends(require_permission("airports.manage"))],
)
async def create_airport(
    data: AirportCreate,
    db: AsyncSession = Depends(get_db),
) -> AirportRead:
    """Create airport."""
    airport = Airport(
        iata_code=data.iata_code.upper(),
        name=data.name,
        city=data.city,
        country=data.country,
        timezone=data.timezone,
        latitude=data.latitude,
        longitude=data.longitude,
        terminal_info=data.terminal_info,
        amenities=data.amenities,
        map_url=data.map_url,
    )
    db.add(airport)
    try:
        await db.commit()
        await db.refresh(airport)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Airport could not be created (duplicate IATA?)",
        ) from None
    return AirportRead.model_validate(airport)


@router.get(
    "/airports",
    response_model=PaginatedResponse[AirportRead],
    dependencies=[Depends(require_permission("airports.manage"))],
)
async def list_airports(
    db: AsyncSession = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
) -> PaginatedResponse[AirportRead]:
    """List all airports (admin) with pagination."""
    total = (await db.execute(select(func.count()).select_from(Airport))).scalar_one()
    offset = (page - 1) * page_size
    result = await db.execute(
        select(Airport).order_by(Airport.iata_code).offset(offset).limit(page_size)
    )
    items = [AirportRead.model_validate(a) for a in result.scalars().all()]
    return PaginatedResponse.create(items=items, total=total, page=page, page_size=page_size)


@router.get(
    "/airports/{airport_id}",
    response_model=AirportRead,
    dependencies=[Depends(require_permission("flights.read"))],
)
async def get_airport(airport_id: int, db: AsyncSession = Depends(get_db)) -> AirportRead:
    """Get airport by id."""
    result = await db.execute(select(Airport).where(Airport.id == airport_id))
    airport = result.scalar_one_or_none()
    if airport is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Airport not found")
    return AirportRead.model_validate(airport)


@router.get(
    "/airports/{iata}/info",
    response_model=AirportDetailRead,
    dependencies=[Depends(require_permission("flights.read"))],
)
async def get_airport_info(iata: str, db: AsyncSession = Depends(get_db)) -> AirportDetailRead:
    """Get full airport details by IATA code (terminal, amenities, location)."""
    result = await db.execute(
        select(Airport).where(Airport.iata_code == iata.upper())
    )
    airport = result.scalar_one_or_none()
    if airport is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Airport not found")
    return AirportDetailRead.model_validate(airport)


@router.patch(
    "/airports/{airport_id}",
    response_model=AirportRead,
    dependencies=[Depends(require_permission("airports.manage"))],
)
async def update_airport(
    airport_id: int,
    data: AirportUpdate,
    db: AsyncSession = Depends(get_db),
) -> AirportRead:
    """Update airport."""
    result = await db.execute(select(Airport).where(Airport.id == airport_id))
    airport = result.scalar_one_or_none()
    if airport is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Airport not found")
    if data.name is not None:
        airport.name = data.name
    if data.city is not None:
        airport.city = data.city
    if data.country is not None:
        airport.country = data.country
    if data.timezone is not None:
        airport.timezone = data.timezone
    if data.latitude is not None:
        airport.latitude = data.latitude
    if data.longitude is not None:
        airport.longitude = data.longitude
    if data.terminal_info is not None:
        airport.terminal_info = data.terminal_info
    if data.amenities is not None:
        airport.amenities = data.amenities
    if data.map_url is not None:
        airport.map_url = data.map_url
    await db.commit()
    await db.refresh(airport)
    return AirportRead.model_validate(airport)


@router.delete(
    "/airports/{airport_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_permission("airports.manage"))],
)
async def delete_airport(airport_id: int, db: AsyncSession = Depends(get_db)) -> None:
    """Delete airport."""
    result = await db.execute(select(Airport).where(Airport.id == airport_id))
    airport = result.scalar_one_or_none()
    if airport is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Airport not found")
    await db.delete(airport)
    await db.commit()
