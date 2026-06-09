"""Tests for hiding reservations from My Trips."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from decimal import Decimal

import pytest
from sqlalchemy import select

from app.models.flights import Flight
from app.models.reservations import Reservation, ReservationStatus
from tests.conftest import _ensure_permission


async def _grant_read_permission(db_session, authed_user):
    user, headers = authed_user
    from app.models.roles import Role

    role = (
        await db_session.execute(select(Role).where(Role.id == user.role_id))
    ).scalar_one()
    await _ensure_permission(db_session, role, "flights.read")
    await db_session.commit()
    return user, headers


async def _reservation_with_flight(
    db_session,
    authed_user,
    *,
    days_until: int,
    status: str = ReservationStatus.PAID.value,
    hidden_at: datetime | None = None,
) -> tuple[Reservation, dict[str, str]]:
    user, headers = await _grant_read_permission(db_session, authed_user)
    now = datetime.now(UTC)
    flight = Flight(
        provider_flight_id=f"mock-hide-{uuid.uuid4().hex[:8]}",
        origin_iata="CAI",
        destination_iata="DXB",
        carrier_code="MS",
        flight_number="111",
        departure_at=now + timedelta(days=days_until),
        arrival_at=now + timedelta(days=days_until, hours=3),
        base_price=Decimal("100.00"),
        currency="USD",
        total_seats=180,
    )
    db_session.add(flight)
    await db_session.flush()

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="9A",
        status=status,
        total_price=Decimal("100.00"),
        currency="USD",
        hidden_at=hidden_at,
    )
    db_session.add(reservation)
    await db_session.commit()
    await db_session.refresh(reservation)
    return reservation, headers


@pytest.mark.asyncio
async def test_hide_canceled_reservation(
    prepare_schema,
    client,
    db_session,
    authed_user,
):
    reservation, headers = await _reservation_with_flight(
        db_session,
        authed_user,
        days_until=5,
        status=ReservationStatus.CANCELED.value,
    )

    res = await client.post(f"/api/v1/reservations/{reservation.id}/hide", headers=headers)
    assert res.status_code == 204

    await db_session.refresh(reservation)
    assert reservation.hidden_at is not None


@pytest.mark.asyncio
async def test_hide_past_reservation(
    prepare_schema,
    client,
    db_session,
    authed_user,
):
    reservation, headers = await _reservation_with_flight(
        db_session,
        authed_user,
        days_until=-2,
        status=ReservationStatus.PAID.value,
    )

    res = await client.post(f"/api/v1/reservations/{reservation.id}/hide", headers=headers)
    assert res.status_code == 204


@pytest.mark.asyncio
async def test_hide_rejects_upcoming_active_reservation(
    prepare_schema,
    client,
    db_session,
    authed_user,
):
    reservation, headers = await _reservation_with_flight(
        db_session,
        authed_user,
        days_until=5,
        status=ReservationStatus.PAID.value,
    )

    res = await client.post(f"/api/v1/reservations/{reservation.id}/hide", headers=headers)
    assert res.status_code == 400


@pytest.mark.asyncio
async def test_list_excludes_hidden_reservations(
    prepare_schema,
    client,
    db_session,
    authed_user,
):
    visible, headers = await _reservation_with_flight(
        db_session,
        authed_user,
        days_until=5,
        status=ReservationStatus.CANCELED.value,
    )
    hidden, _ = await _reservation_with_flight(
        db_session,
        authed_user,
        days_until=-1,
        status=ReservationStatus.PAID.value,
        hidden_at=datetime.now(UTC),
    )

    res = await client.get("/api/v1/reservations/me", headers=headers)
    assert res.status_code == 200
    payload = res.json()
    ids = {item["id"] for item in payload["items"]}
    assert visible.id in ids
    assert hidden.id not in ids
