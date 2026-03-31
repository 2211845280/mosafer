"""Airport CRUD API."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.airports import Airport
from app.schemas.airports import AirportCreate, AirportRead, AirportUpdate

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
    response_model=list[AirportRead],
    dependencies=[Depends(require_permission("airports.manage"))],
)
async def list_airports(db: AsyncSession = Depends(get_db)) -> list[AirportRead]:
    """List all airports (admin)."""
    result = await db.execute(select(Airport).order_by(Airport.iata_code))
    rows = result.scalars().all()
    return [AirportRead.model_validate(a) for a in rows]


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
