"""Checkout session API (pre-payment booking flow)."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import get_current_user
from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.users import User
from app.schemas.blocked_passports import BlockedPassportsRead
from app.schemas.booking_passengers import PassengerDetailsSubmit
from app.schemas.checkout_sessions import (
    CheckoutSessionCreate,
    CheckoutSessionDetailRead,
)
from app.services.checkout_session_service import (
    create_checkout_session,
    get_checkout_session_detail,
    submit_session_passengers,
)
from app.services.passenger_duplicate import list_blocked_passports_on_flight

router = APIRouter()


@router.post(
    "/checkout-sessions",
    response_model=CheckoutSessionDetailRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission("bookings.create"))],
)
async def post_checkout_session(
    data: CheckoutSessionCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CheckoutSessionDetailRead:
    """Hold seats and start checkout without creating a reservation."""
    return await create_checkout_session(db, user_id=user.id, data=data)


@router.get(
    "/checkout-sessions/{session_id}",
    response_model=CheckoutSessionDetailRead,
    dependencies=[Depends(require_permission("bookings.create"))],
)
async def read_checkout_session(
    session_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CheckoutSessionDetailRead:
    return await get_checkout_session_detail(db, session_id=session_id, user_id=user.id)


@router.post(
    "/checkout-sessions/{session_id}/passenger-details",
    response_model=CheckoutSessionDetailRead,
    dependencies=[Depends(require_permission("bookings.create"))],
)
async def post_checkout_session_passengers(
    session_id: int,
    body: PassengerDetailsSubmit,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CheckoutSessionDetailRead:
    return await submit_session_passengers(
        db,
        session_id=session_id,
        user_id=user.id,
        body=body,
    )


@router.get(
    "/checkout-sessions/{session_id}/blocked-passports",
    response_model=BlockedPassportsRead,
    dependencies=[Depends(require_permission("bookings.create"))],
)
async def read_checkout_blocked_passports(
    session_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> BlockedPassportsRead:
    detail = await get_checkout_session_detail(db, session_id=session_id, user_id=user.id)
    blocked = await list_blocked_passports_on_flight(db, flight_id=detail.flight_id)
    return BlockedPassportsRead(blocked_passports=blocked)
