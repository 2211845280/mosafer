"""Payment endpoints: create session, webhook, status, refund."""

from __future__ import annotations

from decimal import Decimal

import structlog
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.payments import Payment
from app.models.reservations import Reservation, ReservationStatus
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User
from app.schemas.payments import (
    PaymentCreateRequest,
    PaymentRead,
    PaymentSessionResponse,
    PaymentWebhookPayload,
    RefundResponse,
)
from app.services.external.mock_payment_service import MockPaymentService
from app.services.notification_dispatcher import NotificationDispatcher

logger = structlog.get_logger(__name__)

router = APIRouter()
_payment_service = MockPaymentService()
_dispatcher = NotificationDispatcher()


@router.post(
    "/payments/create-session",
    response_model=PaymentSessionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_payment_session(
    body: PaymentCreateRequest,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
) -> PaymentSessionResponse:
    """Create a payment session for a reservation."""
    result = await db.execute(
        select(Reservation).where(Reservation.id == body.reservation_id)
    )
    reservation = result.scalar_one_or_none()
    if reservation is None:
        raise HTTPException(status_code=404, detail="Reservation not found")
    if reservation.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not your reservation")
    if reservation.status == ReservationStatus.PAID:
        raise HTTPException(status_code=409, detail="Reservation already paid")
    if reservation.status == ReservationStatus.CANCELED:
        raise HTTPException(status_code=409, detail="Reservation is canceled")

    amount = reservation.total_price or Decimal("0.00")
    currency = reservation.currency or "USD"

    session = await _payment_service.create_session(
        amount=amount,
        currency=currency,
        reservation_id=reservation.id,
        user_id=user.id,
    )

    existing_result = await db.execute(
        select(Payment).where(Payment.provider_payment_id == session["provider_payment_id"])
    )
    existing_payment = existing_result.scalar_one_or_none()
    if existing_payment is not None:
        return PaymentSessionResponse(
            payment_id=existing_payment.id,
            session_id=session["session_id"],
            checkout_url=session["checkout_url"],
            status=existing_payment.status,
        )

    payment = Payment(
        reservation_id=reservation.id,
        user_id=user.id,
        provider="mock",
        provider_payment_id=session["provider_payment_id"],
        amount=amount,
        currency=currency,
        status="pending",
    )
    db.add(payment)
    await db.commit()
    await db.refresh(payment)

    return PaymentSessionResponse(
        payment_id=payment.id,
        session_id=session["session_id"],
        checkout_url=session["checkout_url"],
        status=payment.status,
    )


@router.post("/payments/webhook")
async def payment_webhook(
    payload: PaymentWebhookPayload,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Handle payment provider callback (mock: always valid)."""
    verified = await _payment_service.verify_webhook(
        payload.model_dump(), payload.signature,
    )
    if not verified.get("valid"):
        raise HTTPException(status_code=400, detail="Invalid webhook signature")

    result = await db.execute(
        select(Payment).where(
            Payment.provider_payment_id == payload.provider_payment_id,
        )
    )
    payment = result.scalar_one_or_none()
    if payment is None:
        raise HTTPException(status_code=404, detail="Payment not found")

    payment.status = payload.status

    res_result = await db.execute(
        select(Reservation).where(Reservation.id == payment.reservation_id)
    )
    reservation = res_result.scalar_one_or_none()

    if payload.status == "completed" and reservation:
        reservation.status = ReservationStatus.PAID.value
        await _dispatcher.dispatch(
            user_id=payment.user_id,
            event_type="payment_success",
            title="Payment Successful",
            body=f"Your payment of {payment.amount} {payment.currency} has been processed.",
            data={"payment_id": str(payment.id)},
            db=db,
        )
        logger.info("payment.completed", payment_id=payment.id)
    elif payload.status == "failed" and reservation:
        reservation.status = ReservationStatus.CANCELED.value
        ticket_result = await db.execute(
            select(Ticket).where(Ticket.booking_id == reservation.id)
        )
        ticket = ticket_result.scalar_one_or_none()
        if ticket is not None:
            ticket.status = TicketStatus.CANCELED.value
        await _dispatcher.dispatch(
            user_id=payment.user_id,
            event_type="payment_failed",
            title="Payment Failed",
            body="Your payment could not be processed. Reservation has been canceled.",
            data={"payment_id": str(payment.id)},
            db=db,
        )
        logger.warning("payment.failed", payment_id=payment.id)

    await db.commit()
    return {"status": "ok"}


@router.get(
    "/payments/{payment_id}",
    response_model=PaymentRead,
)
async def get_payment(
    payment_id: int,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
) -> PaymentRead:
    """Get payment status."""
    result = await db.execute(
        select(Payment).where(Payment.id == payment_id)
    )
    payment = result.scalar_one_or_none()
    if payment is None:
        raise HTTPException(status_code=404, detail="Payment not found")
    if payment.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not your payment")
    return PaymentRead.model_validate(payment)


@router.post(
    "/payments/{payment_id}/refund",
    response_model=RefundResponse,
)
async def refund_payment(
    payment_id: int,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
) -> RefundResponse:
    """Refund a completed payment and cancel the reservation."""
    result = await db.execute(
        select(Payment).where(Payment.id == payment_id)
    )
    payment = result.scalar_one_or_none()
    if payment is None:
        raise HTTPException(status_code=404, detail="Payment not found")
    if payment.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not your payment")
    if payment.status != "completed":
        raise HTTPException(status_code=409, detail="Only completed payments can be refunded")

    await _payment_service.refund(
        provider_payment_id=payment.provider_payment_id,
        amount=payment.amount,
    )

    payment.status = "refunded"

    res_result = await db.execute(
        select(Reservation).where(Reservation.id == payment.reservation_id)
    )
    reservation = res_result.scalar_one_or_none()
    if reservation:
        reservation.status = ReservationStatus.CANCELED.value
        ticket_result = await db.execute(
            select(Ticket).where(Ticket.booking_id == reservation.id)
        )
        ticket = ticket_result.scalar_one_or_none()
        if ticket is not None:
            ticket.status = TicketStatus.CANCELED.value

    await _dispatcher.dispatch(
        user_id=payment.user_id,
        event_type="payment_refunded",
        title="Payment Refunded",
        body=f"Your payment of {payment.amount} {payment.currency} has been refunded.",
        data={"payment_id": str(payment.id)},
        db=db,
    )

    await db.commit()

    return RefundResponse(
        payment_id=payment.id,
        refund_status="refunded",
        refunded_amount=payment.amount,
    )
