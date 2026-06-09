"""Seed paid IST outbound trips for indoor-map review demos."""

from __future__ import annotations

import os
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.core.ticket_qr import qr_content_for_ticket, write_qr_png
from app.data.airlines import carrier_name
from app.models.airports import Airport
from app.models.booking_passengers import BookingPassenger
from app.models.flights import Flight
from app.models.passenger import Passenger
from app.models.payments import Payment
from app.models.reservations import Reservation, ReservationStatus
from app.models.roles import Role
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User
from app.models.user_preferences import UserPreference
from app.seed.schedule import seed_departure_datetime
from app.services.airport_seed_data import AIRPORT_SEEDS
from app.services.booking_reference import generate_eticket_number, generate_pnr

DEMO_TRAVELER_EMAIL = os.getenv("DEMO_TRAVELER_EMAIL", "traveler@mosafer.dev")
DEMO_TRAVELER_PASSWORD = os.getenv("DEMO_TRAVELER_PASSWORD", "Travel123!")
DEMO_TRAVELER_NAME = os.getenv("DEMO_TRAVELER_NAME", "Demo Traveler")
TAKSIM_SQUARE_LAT = 41.0369
TAKSIM_SQUARE_LNG = 28.9850
TAKSIM_SQUARE_ADDRESS = "Taksim Square, Istanbul"

SEED_PROVIDER_PREFIX = "SEED-IST-REVIEW-"


@dataclass(frozen=True)
class ReviewTripSpec:
    """One demo booking from Istanbul to an international destination."""

    suffix: str
    destination_iata: str
    carrier_code: str
    flight_number: str
    duration_hours: float
    seat: str
    price: Decimal


# Primary LHR review trip uses TK0244 → gate G12 (see istanbul_gate_data).
REVIEW_TRIPS: tuple[ReviewTripSpec, ...] = (
    ReviewTripSpec(
        suffix="LHR",
        destination_iata="LHR",
        carrier_code="TK",
        flight_number="TK0244",
        duration_hours=4.5,
        seat="14C",
        price=Decimal("580.00"),
    ),
    ReviewTripSpec(
        suffix="CAI",
        destination_iata="CAI",
        carrier_code="TK",
        flight_number="TK690",
        duration_hours=2.5,
        seat="8A",
        price=Decimal("210.00"),
    ),
    ReviewTripSpec(
        suffix="DXB",
        destination_iata="DXB",
        carrier_code="TK",
        flight_number="TK760",
        duration_hours=4.5,
        seat="22F",
        price=Decimal("420.00"),
    ),
    ReviewTripSpec(
        suffix="CDG",
        destination_iata="CDG",
        carrier_code="TK",
        flight_number="TK1823",
        duration_hours=4.0,
        seat="31B",
        price=Decimal("510.00"),
    ),
    ReviewTripSpec(
        suffix="JED",
        destination_iata="JED",
        carrier_code="TK",
        flight_number="TK934",
        duration_hours=3.5,
        seat="5D",
        price=Decimal("385.00"),
    ),
    ReviewTripSpec(
        suffix="FRA",
        destination_iata="FRA",
        carrier_code="TK",
        flight_number="TK1597",
        duration_hours=3.5,
        seat="18A",
        price=Decimal("465.00"),
    ),
    ReviewTripSpec(
        suffix="JFK",
        destination_iata="JFK",
        carrier_code="TK",
        flight_number="TK001",
        duration_hours=11.0,
        seat="42F",
        price=Decimal("890.00"),
    ),
    ReviewTripSpec(
        suffix="AMM",
        destination_iata="AMM",
        carrier_code="TK",
        flight_number="TK812",
        duration_hours=2.5,
        seat="12E",
        price=Decimal("245.00"),
    ),
    ReviewTripSpec(
        suffix="BKK",
        destination_iata="BKK",
        carrier_code="TK",
        flight_number="TK68",
        duration_hours=9.0,
        seat="28A",
        price=Decimal("620.00"),
    ),
    ReviewTripSpec(
        suffix="SIN",
        destination_iata="SIN",
        carrier_code="TK",
        flight_number="TK54",
        duration_hours=11.0,
        seat="33C",
        price=Decimal("710.00"),
    ),
    ReviewTripSpec(
        suffix="KUL",
        destination_iata="KUL",
        carrier_code="TK",
        flight_number="TK60",
        duration_hours=10.0,
        seat="19F",
        price=Decimal("540.00"),
    ),
    ReviewTripSpec(
        suffix="MNL",
        destination_iata="MNL",
        carrier_code="TK",
        flight_number="TK84",
        duration_hours=12.0,
        seat="25D",
        price=Decimal("680.00"),
    ),
    ReviewTripSpec(
        suffix="HAN",
        destination_iata="HAN",
        carrier_code="TK",
        flight_number="TK164",
        duration_hours=10.0,
        seat="16B",
        price=Decimal("590.00"),
    ),
    ReviewTripSpec(
        suffix="SGN",
        destination_iata="SGN",
        carrier_code="TK",
        flight_number="TK162",
        duration_hours=10.5,
        seat="21A",
        price=Decimal("605.00"),
    ),
    ReviewTripSpec(
        suffix="CGK",
        destination_iata="CGK",
        carrier_code="TK",
        flight_number="TK56",
        duration_hours=11.5,
        seat="30E",
        price=Decimal("650.00"),
    ),
    ReviewTripSpec(
        suffix="DPS",
        destination_iata="DPS",
        carrier_code="TK",
        flight_number="TK66",
        duration_hours=12.0,
        seat="27G",
        price=Decimal("695.00"),
    ),
)


def _airport_seed_by_iata(iata: str) -> dict | None:
    code = iata.upper()
    for row in AIRPORT_SEEDS:
        if row["iata_code"] == code:
            return row
    return None


async def _ensure_airport(db: AsyncSession, iata: str) -> Airport | None:
    seed = _airport_seed_by_iata(iata)
    if seed is None:
        return None

    result = await db.execute(select(Airport).where(Airport.iata_code == iata.upper()))
    airport = result.scalar_one_or_none()
    if airport is None:
        airport = Airport(
            iata_code=seed["iata_code"],
            name=seed["name"],
            city=seed["city"],
            country=seed["country"],
            timezone=seed.get("timezone"),
            latitude=seed.get("latitude"),
            longitude=seed.get("longitude"),
            terminal_info=seed.get("terminal_info"),
            amenities=seed.get("amenities"),
            map_url=seed.get("map_url"),
        )
        db.add(airport)
        await db.flush()
    return airport


async def _ensure_demo_user(db: AsyncSession) -> User:
    result = await db.execute(select(User).where(User.email == DEMO_TRAVELER_EMAIL))
    user = result.scalar_one_or_none()
    if user is not None:
        return user

    role_result = await db.execute(select(Role).where(Role.name == "user"))
    default_role = role_result.scalar_one_or_none()

    user = User(
        email=DEMO_TRAVELER_EMAIL,
        password_hash=hash_password(DEMO_TRAVELER_PASSWORD),
        role_id=default_role.id if default_role else None,
        is_email_verified=True,
        email_verification_token=None,
    )
    db.add(user)
    await db.flush()

    db.add(
        Passenger(
            user_id=user.id,
            full_name=DEMO_TRAVELER_NAME,
            phone="+905551234567",
            passport_image="placeholder://seed",
            account_status="active",
        ),
    )
    await db.flush()
    return user


async def _ensure_demo_preferences(db: AsyncSession, user: User) -> None:
    """Keep review route origin fixed at Taksim Square for demo trips."""
    result = await db.execute(
        select(UserPreference).where(UserPreference.user_id == user.id),
    )
    pref = result.scalar_one_or_none()
    if pref is None:
        pref = UserPreference(user_id=user.id)
        db.add(pref)

    pref.home_address = TAKSIM_SQUARE_ADDRESS
    pref.home_lat = TAKSIM_SQUARE_LAT
    pref.home_lng = TAKSIM_SQUARE_LNG
    pref.preferred_transport = "car"


def _departure_arrival(spec: ReviewTripSpec) -> tuple[datetime, datetime]:
    departure = seed_departure_datetime(f"review-ist-{spec.suffix}")
    arrival = departure + timedelta(hours=spec.duration_hours)
    return departure, arrival


async def _seed_one_trip(
    db: AsyncSession,
    *,
    user: User,
    spec: ReviewTripSpec,
) -> tuple[str, bool]:
    """Insert one paid reservation; returns (provider_flight_id, created)."""
    provider_flight_id = f"{SEED_PROVIDER_PREFIX}{spec.suffix}"

    existing_flight = await db.execute(
        select(Flight).where(Flight.provider_flight_id == provider_flight_id),
    )
    flight = existing_flight.scalar_one_or_none()
    if flight is not None:
        departure_at, arrival_at = _departure_arrival(spec)
        flight.departure_at = departure_at
        flight.arrival_at = arrival_at
        flight.flight_number = spec.flight_number
        existing_res = await db.execute(
            select(Reservation).where(
                Reservation.user_id == user.id,
                Reservation.flight_id == flight.id,
            ),
        )
        if existing_res.scalar_one_or_none() is not None:
            return provider_flight_id, False

    origin = await _ensure_airport(db, "IST")
    destination = await _ensure_airport(db, spec.destination_iata)
    departure_at, arrival_at = _departure_arrival(spec)

    if flight is None:
        flight = Flight(
            provider_flight_id=provider_flight_id,
            origin_iata="IST",
            destination_iata=spec.destination_iata,
            carrier_code=spec.carrier_code,
            flight_number=spec.flight_number,
            origin_airport_id=origin.id if origin else None,
            destination_airport_id=destination.id if destination else None,
            departure_at=departure_at,
            arrival_at=arrival_at,
            base_price=spec.price,
            currency="USD",
        )
        db.add(flight)
        await db.flush()
    else:
        flight.departure_at = departure_at
        flight.arrival_at = arrival_at
        flight.flight_number = spec.flight_number

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat=spec.seat,
        status=ReservationStatus.PAID.value,
        total_price=spec.price,
        currency="USD",
        adults_count=1,
        pnr=generate_pnr(),
        cabin_class="economy",
        passenger_details_completed_at=datetime.now(UTC),
    )
    db.add(reservation)
    await db.flush()

    ticket_number = generate_eticket_number(spec.carrier_code)
    passenger_display = "TRAVELER/DEMO"
    qr_plain = qr_content_for_ticket(
        ticket_number,
        flight_id=flight.id,
        origin_iata=flight.origin_iata,
        destination_iata=flight.destination_iata,
        departure_at=flight.departure_at.isoformat(),
        carrier_code=flight.carrier_code,
        flight_number=flight.flight_number,
        seat=spec.seat,
        pnr=reservation.pnr,
        passenger_name=passenger_display,
        carrier_name=carrier_name(flight.carrier_code),
    )
    safe_name = ticket_number.replace("-", "")
    db.add(
        Ticket(
            booking_id=reservation.id,
            ticket_number=ticket_number,
            qr_code=qr_plain,
            qr_image_path=write_qr_png(qr_plain, f"{safe_name}.png"),
            status=TicketStatus.VALID.value,
        ),
    )

    db.add(
        BookingPassenger(
            reservation_id=reservation.id,
            sequence=1,
            title="MR",
            given_name="DEMO",
            family_name="TRAVELER",
            date_of_birth=date(1990, 5, 15),
            gender="M",
            nationality="TUR",
            passport_number="U12345678",
            passport_expiry=date(2030, 12, 31),
            passport_issuing_country="TUR",
        ),
    )

    db.add(
        Payment(
            reservation_id=reservation.id,
            user_id=user.id,
            provider="mock",
            provider_payment_id=f"seed-pay-{provider_flight_id.lower()}",
            amount=spec.price,
            currency="USD",
            status="completed",
        ),
    )
    return provider_flight_id, True


async def seed_istanbul_review_trips(db: AsyncSession) -> dict:
    """Create demo traveler and IST outbound paid trips (idempotent)."""
    user = await _ensure_demo_user(db)
    await _ensure_demo_preferences(db, user)
    created: list[str] = []
    skipped: list[str] = []

    for spec in REVIEW_TRIPS:
        provider_id, was_created = await _seed_one_trip(db, user=user, spec=spec)
        if was_created:
            created.append(provider_id)
        else:
            skipped.append(provider_id)

    await db.commit()
    return {
        "email": DEMO_TRAVELER_EMAIL,
        "password": DEMO_TRAVELER_PASSWORD,
        "created": created,
        "skipped": skipped,
        "total_trips": len(REVIEW_TRIPS),
    }
