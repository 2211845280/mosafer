"""Flight identity helpers — one DB row per route + departure date."""

from __future__ import annotations

from datetime import UTC, date, datetime
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.flights import Flight

_MAX_PROVIDER_FLIGHT_ID_LEN = 128


def departure_calendar_date(value: datetime) -> date:
    """Calendar date of departure in UTC (naive values treated as UTC)."""
    if value.tzinfo is None:
        return value.date()
    return value.astimezone(UTC).date()


def dated_provider_flight_id(provider_flight_id: str, departure_at: datetime) -> str:
    """Return a stable provider id that includes the departure calendar date."""
    base = provider_flight_id.strip()
    if "#" in base:
        return base[:_MAX_PROVIDER_FLIGHT_ID_LEN]
    dep_date = departure_calendar_date(departure_at)
    dated = f"{base}#{dep_date.isoformat()}"
    return dated[:_MAX_PROVIDER_FLIGHT_ID_LEN]


async def resolve_flight_for_booking(
    db: AsyncSession,
    *,
    provider_flight_id: str,
    departure_at: datetime,
    arrival_at: datetime,
    origin_iata: str,
    destination_iata: str,
    carrier_code: str,
    flight_number: str,
    base_price: Decimal | None,
    currency: str | None,
    total_seats: int | None = None,
) -> Flight:
    """Find or create a flight row for this route + departure date."""
    dated_id = dated_provider_flight_id(provider_flight_id, departure_at)
    requested_date = departure_calendar_date(departure_at)

    result = await db.execute(
        select(Flight).where(Flight.provider_flight_id == dated_id),
    )
    flight = result.scalar_one_or_none()
    if flight is not None:
        return flight

    legacy_id = provider_flight_id.strip()
    if legacy_id != dated_id:
        legacy_result = await db.execute(
            select(Flight).where(Flight.provider_flight_id == legacy_id),
        )
        legacy_flight = legacy_result.scalar_one_or_none()
        if legacy_flight is not None:
            if departure_calendar_date(legacy_flight.departure_at) == requested_date:
                return legacy_flight

    flight = Flight(
        provider_flight_id=dated_id,
        origin_iata=origin_iata.upper(),
        destination_iata=destination_iata.upper(),
        carrier_code=carrier_code.upper(),
        flight_number=flight_number.strip(),
        departure_at=departure_at,
        arrival_at=arrival_at,
        base_price=base_price,
        currency=currency.upper() if currency else None,
        total_seats=total_seats,
    )
    db.add(flight)
    await db.flush()
    return flight
