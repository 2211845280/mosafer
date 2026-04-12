"""Shared integration test fixtures."""

from __future__ import annotations

import uuid
from collections.abc import AsyncGenerator
from datetime import UTC, datetime, timedelta
from decimal import Decimal

import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import create_access_token
from app.db.database import AsyncSessionLocal, Base, engine, get_db
from app.main import app
from app.models.airports import Airport
from app.models.flights import Flight
from app.models.payments import Payment
from app.models.permissions import Permission
from app.models.reservations import Reservation, ReservationStatus
from app.models.role_permissions import RolePermission
from app.models.roles import Role
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User


@pytest_asyncio.fixture
async def prepare_schema() -> AsyncGenerator[None, None]:
    """Create/drop all tables for isolation in integration tests."""
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    except Exception as exc:  # pragma: no cover - environment-dependent
        pytest.skip(f"Integration DB is not reachable: {exc}")
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def _override_get_db() -> AsyncGenerator[AsyncSession, None]:
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    async with AsyncClient(app=app, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


async def _ensure_permission(session: AsyncSession, role: Role, perm_name: str) -> None:
    perm = (
        await session.execute(select(Permission).where(Permission.name == perm_name))
    ).scalar_one_or_none()
    if perm is None:
        perm = Permission(name=perm_name, description=f"perm {perm_name}")
        session.add(perm)
        await session.flush()
    existing = (
        await session.execute(
            select(RolePermission).where(
                RolePermission.role_id == role.id,
                RolePermission.permission_id == perm.id,
            )
        )
    ).scalar_one_or_none()
    if existing is None:
        session.add(RolePermission(role_id=role.id, permission_id=perm.id))


@pytest_asyncio.fixture
async def authed_user(db_session: AsyncSession) -> tuple[User, dict[str, str]]:
    role = Role(name="tester", description="test role")
    db_session.add(role)
    await db_session.flush()
    for p in ("bookings.create", "tickets.view", "flights.read"):
        await _ensure_permission(db_session, role, p)

    user = User(
        email=f"tester-{uuid.uuid4().hex[:8]}@example.com",
        password_hash="hashed",
        role_id=role.id,
        is_active=True,
        is_email_verified=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    token = create_access_token({"sub": str(user.id)})
    return user, {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def seeded_flight(db_session: AsyncSession) -> Flight:
    origin = Airport(iata_code="CAI", name="Cairo", city="Cairo", country="Egypt", timezone="Africa/Cairo")
    destination = Airport(
        iata_code="DXB",
        name="Dubai",
        city="Dubai",
        country="UAE",
        timezone="Asia/Dubai",
    )
    db_session.add_all([origin, destination])
    await db_session.flush()

    now = datetime.now(UTC)
    flight = Flight(
        provider_flight_id=f"mock-{uuid.uuid4().hex[:10]}",
        origin_iata="CAI",
        destination_iata="DXB",
        carrier_code="MS",
        flight_number="123",
        origin_airport_id=origin.id,
        destination_airport_id=destination.id,
        departure_at=now + timedelta(days=2),
        arrival_at=now + timedelta(days=2, hours=3),
        base_price=Decimal("100.00"),
        currency="USD",
        total_seats=180,
    )
    db_session.add(flight)
    await db_session.commit()
    await db_session.refresh(flight)
    return flight


@pytest_asyncio.fixture
async def seeded_reservation(
    db_session: AsyncSession,
    authed_user: tuple[User, dict[str, str]],
    seeded_flight: Flight,
) -> Reservation:
    user, _ = authed_user
    reservation = Reservation(
        user_id=user.id,
        flight_id=seeded_flight.id,
        seat="12A",
        status=ReservationStatus.BOOKED.value,
        total_price=Decimal("150.00"),
        currency="USD",
    )
    db_session.add(reservation)
    await db_session.commit()
    await db_session.refresh(reservation)
    return reservation


@pytest_asyncio.fixture
async def seeded_ticket(
    db_session: AsyncSession,
    seeded_reservation: Reservation,
) -> Ticket:
    ticket = Ticket(
        booking_id=seeded_reservation.id,
        ticket_number=f"TN{uuid.uuid4().hex[:10]}".upper(),
        qr_code="{}",
        status=TicketStatus.VALID.value,
    )
    db_session.add(ticket)
    await db_session.commit()
    await db_session.refresh(ticket)
    return ticket


@pytest_asyncio.fixture
async def seeded_payment(
    db_session: AsyncSession,
    authed_user: tuple[User, dict[str, str]],
    seeded_reservation: Reservation,
) -> Payment:
    user, _ = authed_user
    payment = Payment(
        reservation_id=seeded_reservation.id,
        user_id=user.id,
        provider="mock",
        provider_payment_id=f"mock_pay_{uuid.uuid4().hex[:16]}",
        amount=Decimal("150.00"),
        currency="USD",
        status="pending",
    )
    db_session.add(payment)
    await db_session.commit()
    await db_session.refresh(payment)
    return payment
