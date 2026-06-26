#!/usr/bin/env python3
"""Dev helper: schedule a trip so reminder notifications fire immediately.

Usage:
    uv run python scripts/trigger_departure_notification_test.py \\
        --email abdo@gmail.com --type departure --tier critical

    uv run python scripts/trigger_departure_notification_test.py \\
        --email abdo@gmail.com --type todo --tier 3d

    uv run python scripts/trigger_departure_notification_test.py \\
        --email abdo@gmail.com --type departure --tier all

Requires: PostgreSQL + Redis (e.g. docker compose up -d).
"""

from __future__ import annotations

import argparse
import asyncio
from datetime import UTC, datetime, timedelta
from decimal import Decimal

import redis.asyncio as aioredis
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.db.database import AsyncSessionLocal
from app.models.airports import Airport
from app.models.flights import Flight
from app.models.notifications import Notification
from app.models.reservations import Reservation, ReservationStatus
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User
from app.models.user_preferences import UserPreference
from app.schemas.departure_plan import TransportMode
from app.seed.istanbul_review_trips import (
    TAKSIM_SQUARE_ADDRESS,
    TAKSIM_SQUARE_LAT,
    TAKSIM_SQUARE_LNG,
    _airport_seed_by_iata,
    _ensure_airport,
)
from app.services.booking_reference import generate_eticket_number, generate_pnr
from app.services.departure_planner import DeparturePlanner
from app.workers.departure_alert import check_departure_alerts
from app.workers.trip_todo_reminder import check_trip_todo_reminders

# (event_type, target_minutes_until, reference: flight | leave)
_DEPARTURE_TIERS: dict[str, tuple[str, float, str]] = {
    "critical": ("home_departure_critical", 10, "leave"),
    "30m": ("home_departure_30m", 25, "leave"),
    "2h": ("home_departure_2h", 110, "leave"),
    "flight_6h": ("flight_departure_6h", 350, "flight"),
}

_TODO_TIERS: dict[str, tuple[str, float, str]] = {
    "14d": ("trip_todo_14d", 13 * 24 * 60, "flight"),
    "7d": ("trip_todo_7d", 6.5 * 24 * 60, "flight"),
    "3d": ("trip_todo_3d", 2.5 * 24 * 60, "flight"),
    "1d": ("trip_todo_1d", 20 * 60, "flight"),
    "6h": ("trip_todo_6h", 5 * 60, "leave"),
    "3h": ("trip_todo_3h", 2.5 * 60, "leave"),
}

_TEST_PROVIDER_PREFIX = "NOTIF-TEST-IST-"


async def _ensure_airport_coords(db, iata: str) -> Airport:
    code = iata.upper()
    result = await db.execute(select(Airport).where(Airport.iata_code == code))
    airport = result.scalar_one_or_none()
    seed = _airport_seed_by_iata(code)

    if airport is None:
        airport = await _ensure_airport(db, code)
    elif seed and (airport.latitude is None or airport.longitude is None):
        airport.latitude = seed.get("latitude")
        airport.longitude = seed.get("longitude")
        airport.country = airport.country or seed.get("country")
        await db.flush()

    if airport is None or airport.latitude is None or airport.longitude is None:
        raise RuntimeError(f"Airport {iata} missing coordinates in seed data")
    return airport


async def _find_user(db, email: str) -> User | None:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def _ensure_preferences(db, user: User) -> UserPreference:
    result = await db.execute(
        select(UserPreference).where(UserPreference.user_id == user.id),
    )
    pref = result.scalar_one_or_none()
    if pref is None:
        pref = UserPreference(user_id=user.id)
        db.add(pref)

    pref.home_address = pref.home_address or TAKSIM_SQUARE_ADDRESS
    pref.home_lat = float(pref.home_lat or TAKSIM_SQUARE_LAT)
    pref.home_lng = float(pref.home_lng or TAKSIM_SQUARE_LNG)
    pref.preferred_transport = "driving"
    pref.notification_enabled = True
    await db.flush()
    return pref


async def _find_active_reservation(db, user_id: int) -> Reservation | None:
    now = datetime.now(UTC)
    result = await db.execute(
        select(Reservation)
        .join(Flight, Reservation.flight_id == Flight.id)
        .where(
            Reservation.user_id == user_id,
            Reservation.status != ReservationStatus.CANCELED.value,
            Flight.origin_iata == "IST",
            Flight.departure_at >= now,
        )
        .options(selectinload(Reservation.flight))
        .order_by(Flight.departure_at.asc())
        .limit(1),
    )
    return result.scalar_one_or_none()


async def _create_test_reservation(db, user: User) -> Reservation:
    provider_flight_id = f"{_TEST_PROVIDER_PREFIX}{user.id}"
    existing = await db.execute(
        select(Flight).where(Flight.provider_flight_id == provider_flight_id),
    )
    flight = existing.scalar_one_or_none()

    origin = await _ensure_airport(db, "IST")
    destination = await _ensure_airport(db, "LHR")
    if origin is None or destination is None:
        raise RuntimeError("IST/LHR airports missing from seed data")

    now = datetime.now(UTC)
    if flight is None:
        flight = Flight(
            provider_flight_id=provider_flight_id,
            origin_iata="IST",
            destination_iata="LHR",
            carrier_code="TK",
            flight_number="TK0244",
            origin_airport_id=origin.id,
            destination_airport_id=destination.id,
            departure_at=now + timedelta(hours=5),
            arrival_at=now + timedelta(hours=9, minutes=30),
            base_price=Decimal("580.00"),
            currency="USD",
        )
        db.add(flight)
        await db.flush()
    else:
        existing_res = await db.execute(
            select(Reservation).where(
                Reservation.user_id == user.id,
                Reservation.flight_id == flight.id,
                Reservation.status != ReservationStatus.CANCELED.value,
            ),
        )
        reservation = existing_res.scalar_one_or_none()
        if reservation is not None:
            await db.refresh(reservation, attribute_names=["flight"])
            return reservation

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="14C",
        status=ReservationStatus.PAID.value,
        total_price=Decimal("580.00"),
        currency="USD",
        adults_count=1,
        pnr=generate_pnr(),
        cabin_class="economy",
        passenger_details_completed_at=now,
    )
    db.add(reservation)
    await db.flush()

    ticket_result = await db.execute(
        select(Ticket).where(Ticket.booking_id == reservation.id),
    )
    if ticket_result.scalar_one_or_none() is None:
        ticket_number = generate_eticket_number("TK")
        db.add(
            Ticket(
                booking_id=reservation.id,
                ticket_number=ticket_number,
                qr_code=f"NOTIF-TEST:{ticket_number}",
                qr_image_path="placeholder://notif-test",
                status=TicketStatus.VALID.value,
            ),
        )

    await db.refresh(reservation, attribute_names=["flight"])
    return reservation


async def _resolve_departure_at(
    planner: DeparturePlanner,
    *,
    pref: UserPreference,
    flight: Flight,
    origin_airport: Airport,
    dest_airport: Airport | None,
    target_minutes_until_leave: float,
) -> tuple[datetime, datetime]:
    """Return (departure_at, leave_at) matching leave-time thresholds."""
    now = datetime.now(UTC)
    transport = TransportMode(pref.preferred_transport or "driving")

    guess = now + timedelta(minutes=target_minutes_until_leave + 240)
    leave_at = now

    for _ in range(30):
        plan = await planner.calculate(
            user_lat=float(pref.home_lat),
            user_lng=float(pref.home_lng),
            airport_lat=float(origin_airport.latitude),
            airport_lng=float(origin_airport.longitude),
            airport_country=origin_airport.country,
            origin_country=origin_airport.country,
            departure_at=guess,
            transport_mode=transport,
            destination_airport_lat=(
                float(dest_airport.latitude) if dest_airport and dest_airport.latitude else None
            ),
            destination_airport_lng=(
                float(dest_airport.longitude) if dest_airport and dest_airport.longitude else None
            ),
            arrival_at=flight.arrival_at,
        )
        leave_at = plan.leave_at
        if leave_at.tzinfo is None:
            leave_at = leave_at.replace(tzinfo=UTC)

        minutes_until_leave = (leave_at - now).total_seconds() / 60
        error = minutes_until_leave - target_minutes_until_leave
        if abs(error) <= 2:
            return guess, leave_at

        guess = guess - timedelta(minutes=error)

    return guess, leave_at


async def _clear_dedup_keys(redis_client, reservation_id: int, prefix: str) -> int:
    pattern = f"{prefix}:{reservation_id}:*"
    deleted = 0
    async for key in redis_client.scan_iter(match=pattern, count=50):
        await redis_client.delete(key)
        deleted += 1
    return deleted


async def _run_worker(worker_type: str) -> int:
    ctx: dict = {}
    redis_client = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
    ctx["db"] = AsyncSessionLocal
    ctx["redis"] = redis_client
    try:
        if worker_type == "todo":
            return await check_trip_todo_reminders(ctx)
        return await check_departure_alerts(ctx)
    finally:
        await redis_client.aclose()


async def _latest_notification(db, user_id: int) -> Notification | None:
    result = await db.execute(
        select(Notification)
        .where(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc())
        .limit(1),
    )
    return result.scalar_one_or_none()


async def _trigger_one(
    *,
    email: str,
    reservation_id: int,
    worker_type: str,
    tier_key: str,
    redis_client,
) -> None:
    tiers = _TODO_TIERS if worker_type == "todo" else _DEPARTURE_TIERS
    event_type, target_minutes, reference = tiers[tier_key]
    dedup_prefix = "trip_todo_alert" if worker_type == "todo" else "departure_alert"

    async with AsyncSessionLocal() as db:
        user = await _find_user(db, email)
        if user is None:
            raise RuntimeError(f"User not found: {email}")

        pref = await _ensure_preferences(db, user)
        result = await db.execute(
            select(Reservation)
            .where(Reservation.id == reservation_id)
            .options(selectinload(Reservation.flight)),
        )
        reservation = result.scalar_one_or_none()
        if reservation is None:
            raise RuntimeError(f"Reservation {reservation_id} not found")

        flight = reservation.flight
        origin_airport = await _ensure_airport_coords(db, flight.origin_iata)
        dest_airport = await _ensure_airport_coords(db, flight.destination_iata)

        duration = flight.arrival_at - flight.departure_at
        if duration.total_seconds() <= 0:
            duration = timedelta(hours=4, minutes=30)

        now = datetime.now(UTC)
        if reference == "flight":
            departure_at = now + timedelta(minutes=target_minutes)
            leave_at = departure_at - timedelta(hours=3)
        else:
            departure_at, leave_at = await _resolve_departure_at(
                DeparturePlanner(),
                pref=pref,
                flight=flight,
                origin_airport=origin_airport,
                dest_airport=dest_airport,
                target_minutes_until_leave=target_minutes,
            )

        flight.departure_at = departure_at
        flight.arrival_at = departure_at + duration
        await db.commit()

    cleared = await _clear_dedup_keys(redis_client, reservation_id, dedup_prefix)
    alerts = await _run_worker(worker_type)

    async with AsyncSessionLocal() as read_db:
        user = await _find_user(read_db, email)
        note = await _latest_notification(read_db, user.id) if user else None

    print()
    print(f"--- {tier_key.upper()} ({event_type}) ---")
    print(f"  reservation_id: {reservation_id}")
    print(f"  departure_at:   {departure_at.isoformat()}")
    print(f"  leave_at:       {leave_at.isoformat()}")
    print(f"  target_min:     {target_minutes} until {reference}")
    print(f"  redis_cleared:  {cleared} dedup key(s)")
    print(f"  alerts_created: {alerts}")
    if note:
        print(f"  latest_notify:  [{note.type}] {note.title}")
    print("  >> Refresh notifications on your phone now.")


async def main() -> int:
    departure_tier_choices = list(_DEPARTURE_TIERS.keys()) + ["all"]
    todo_tier_choices = list(_TODO_TIERS.keys()) + ["all"]

    parser = argparse.ArgumentParser(
        description="Trigger trip todo or departure notifications for dev testing",
    )
    parser.add_argument("--email", default="abdo@gmail.com", help="Traveler account email")
    parser.add_argument(
        "--type",
        choices=["departure", "todo"],
        default="departure",
        help="Which worker to exercise",
    )
    parser.add_argument(
        "--tier",
        default="critical",
        help="Tier key (departure: critical|30m|2h|flight_6h|all; todo: 14d|7d|3d|1d|6h|3h|all)",
    )
    args = parser.parse_args()

    tiers_map = _TODO_TIERS if args.type == "todo" else _DEPARTURE_TIERS
    valid = set(tiers_map.keys()) | {"all"}
    if args.tier not in valid:
        parser.error(f"Invalid tier {args.tier!r} for type {args.type!r}")

    tiers = list(tiers_map.keys()) if args.tier == "all" else [args.tier]

    redis_client = aioredis.from_url(settings.REDIS_URL, decode_responses=True)

    try:
        async with AsyncSessionLocal() as db:
            user = await _find_user(db, args.email)
            if user is None:
                print(f"User not found: {args.email}")
                print("Register this account in the app first, then re-run.")
                return 1

            pref = await _ensure_preferences(db, user)
            reservation = await _find_active_reservation(db, user.id)
            if reservation is None:
                print(f"No active IST trip for {args.email}; creating test reservation...")
                reservation = await _create_test_reservation(db, user)
            await db.commit()

            print(f"User:         {user.email} (id={user.id})")
            print(f"Reservation:  {reservation.id}")
            print(f"Flight:       {reservation.flight.carrier_code}{reservation.flight.flight_number}")
            print(f"Home:         {pref.home_lat}, {pref.home_lng}")
            print(f"Worker type:  {args.type}")
            print(f"Notifications enabled: {pref.notification_enabled}")

            for index, tier in enumerate(tiers):
                if index > 0:
                    print()
                    print("Waiting 2s before next tier...")
                    await asyncio.sleep(2)

                await _trigger_one(
                    email=args.email,
                    reservation_id=reservation.id,
                    worker_type=args.type,
                    tier_key=tier,
                    redis_client=redis_client,
                )

        print()
        print("Done. Open the app notifications screen on your phone.")
        return 0
    finally:
        await redis_client.aclose()


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
