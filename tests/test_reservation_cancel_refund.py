"""Tests for reservation cancel with refund policy."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from decimal import Decimal

import pytest
from sqlalchemy import select

from app.models.flights import Flight
from app.models.payments import Payment
from app.models.reservations import Reservation, ReservationStatus
from app.models.roles import Role
from app.models.tickets import Ticket, TicketStatus
from app.services.reservation_cancel_service import calculate_refund, days_until_departure
from tests.conftest import _ensure_permission


async def _grant_cancel_permission(db_session, authed_user):
    user, headers = authed_user
    role = (
        await db_session.execute(select(Role).where(Role.id == user.role_id))
    ).scalar_one()
    await _ensure_permission(db_session, role, "bookings.cancel")
    await db_session.commit()
    return user, headers


async def _paid_reservation(
    db_session,
    authed_user,
    *,
    days_until: int,
    amount: str = "100.00",
) -> tuple[Reservation, dict[str, str]]:
    user, headers = await _grant_cancel_permission(db_session, authed_user)
    now = datetime.now(UTC)
    flight = Flight(
        provider_flight_id=f"mock-cancel-{uuid.uuid4().hex[:8]}",
        origin_iata="CAI",
        destination_iata="DXB",
        carrier_code="MS",
        flight_number="999",
        departure_at=now + timedelta(days=days_until),
        arrival_at=now + timedelta(days=days_until, hours=3),
        base_price=Decimal(amount),
        currency="USD",
        total_seats=180,
    )
    db_session.add(flight)
    await db_session.flush()

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="8C",
        status=ReservationStatus.PAID.value,
        total_price=Decimal(amount),
        currency="USD",
    )
    db_session.add(reservation)
    await db_session.flush()

    db_session.add(
        Ticket(
            booking_id=reservation.id,
            ticket_number=f"TN{uuid.uuid4().hex[:8]}".upper(),
            qr_code="{}",
            status=TicketStatus.VALID.value,
        )
    )
    db_session.add(
        Payment(
            reservation_id=reservation.id,
            user_id=user.id,
            provider="mock",
            provider_payment_id=f"mock_pay_{uuid.uuid4().hex[:12]}",
            amount=Decimal(amount),
            currency="USD",
            status="completed",
        )
    )
    await db_session.commit()
    await db_session.refresh(reservation)
    return reservation, headers


def test_days_until_departure_calendar_days():
    now = datetime(2026, 6, 5, 15, 0, tzinfo=UTC)
    departure = datetime(2026, 6, 10, 8, 0, tzinfo=UTC)
    assert days_until_departure(departure, now) == 5


def test_calculate_refund_full_when_more_than_three_days():
    refund, penalty, kind = calculate_refund(Decimal("100.00"), 4)
    assert kind == "full"
    assert refund == Decimal("100.00")
    assert penalty == Decimal("0.00")


def test_calculate_refund_partial_when_three_days_or_less():
    refund, penalty, kind = calculate_refund(Decimal("100.00"), 3)
    assert kind == "partial"
    assert refund == Decimal("50.00")
    assert penalty == Decimal("50.00")


@pytest.mark.asyncio
async def test_cancel_paid_full_refund(prepare_schema, client, db_session, authed_user):
    reservation, headers = await _paid_reservation(db_session, authed_user, days_until=10)
    response = await client.post(
        f"/api/v1/reservations/{reservation.id}/cancel",
        headers=headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["refund_type"] == "full"
    assert body["refunded_amount"] == "100.00"
    assert body["penalty_amount"] == "0.00"
    assert body["reservation"]["status"] == "canceled"

    refreshed = (
        await db_session.execute(select(Reservation).where(Reservation.id == reservation.id))
    ).scalar_one()
    assert refreshed.status == "canceled"


@pytest.mark.asyncio
async def test_cancel_paid_partial_refund(prepare_schema, client, db_session, authed_user):
    reservation, headers = await _paid_reservation(db_session, authed_user, days_until=2)
    response = await client.post(
        f"/api/v1/reservations/{reservation.id}/cancel",
        headers=headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["refund_type"] == "partial"
    assert body["refunded_amount"] == "50.00"
    assert body["penalty_amount"] == "50.00"


@pytest.mark.asyncio
async def test_cancel_booked_no_refund(
    prepare_schema,
    client,
    db_session,
    authed_user,
    seeded_reservation,
    seeded_ticket,
):
    _, headers = await _grant_cancel_permission(db_session, authed_user)
    response = await client.post(
        f"/api/v1/reservations/{seeded_reservation.id}/cancel",
        headers=headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["refund_type"] == "none"
    assert body["refunded_amount"] is None


@pytest.mark.asyncio
async def test_cancel_twice_rejected(prepare_schema, client, db_session, authed_user):
    reservation, headers = await _paid_reservation(db_session, authed_user, days_until=10)
    first = await client.post(
        f"/api/v1/reservations/{reservation.id}/cancel",
        headers=headers,
    )
    assert first.status_code == 200
    second = await client.post(
        f"/api/v1/reservations/{reservation.id}/cancel",
        headers=headers,
    )
    assert second.status_code == 400
