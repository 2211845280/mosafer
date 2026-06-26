"""Payment endpoints: create session, webhook, status, refund."""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal

import structlog
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.checkout_sessions import CheckoutSession, CheckoutSessionStatus
from app.models.payments import Payment
from app.models.reservations import Reservation, ReservationStatus
from app.models.tickets import Ticket, TicketStatus
from app.models.user_preferences import UserPreference
from app.models.users import User
from app.schemas.payments import (
    PaymentConfigResponse,
    PaymentCreateRequest,
    PaymentRead,
    PaymentSessionResponse,
    PaymentWebhookPayload,
    RefundResponse,
    StripeVerifyRequest,
)
from app.services.booking_reference import generate_pnr
from app.services.notification_dispatcher import NotificationDispatcher
from app.services.notification_copy import (
    payment_failed_copy,
    payment_refunded_copy,
    payment_success_copy,
)
from app.services.checkout_session_service import materialize_paid_reservation
from app.services.payment_service import active_payment_provider, get_payment_service

logger = structlog.get_logger(__name__)

router = APIRouter()
_dispatcher = NotificationDispatcher()


async def _user_locale(db: AsyncSession, user_id: int) -> str:
    result = await db.execute(
        select(UserPreference.language).where(UserPreference.user_id == user_id)
    )
    language = result.scalar_one_or_none()
    return language if language else "en"


async def _load_owned_payment(
    payment_id: int,
    user: User,
    db: AsyncSession,
) -> Payment:
    result = await db.execute(select(Payment).where(Payment.id == payment_id))
    payment = result.scalar_one_or_none()
    if payment is None:
        raise HTTPException(status_code=404, detail="Payment not found")
    if payment.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not your payment")
    return payment


async def _apply_payment_status(
    db: AsyncSession,
    payment: Payment,
    *,
    new_status: str,
) -> None:
    if payment.status == new_status:
        return

    payment.status = new_status

    reservation: Reservation | None = None
    if payment.reservation_id is not None:
        res_result = await db.execute(
            select(Reservation)
            .options(
                selectinload(Reservation.flight),
                selectinload(Reservation.ticket),
                selectinload(Reservation.passengers),
            )
            .where(Reservation.id == payment.reservation_id),
        )
        reservation = res_result.scalar_one_or_none()

    if new_status == "completed":
        if reservation is None and payment.checkout_session_id is not None:
            session_result = await db.execute(
                select(CheckoutSession)
                .options(selectinload(CheckoutSession.flight))
                .where(CheckoutSession.id == payment.checkout_session_id),
            )
            session = session_result.scalar_one_or_none()
            if session is None:
                raise HTTPException(status_code=404, detail="Checkout session not found")
            reservation = await materialize_paid_reservation(
                db,
                session=session,
                payment=payment,
            )
        elif reservation is not None:
            reservation.status = ReservationStatus.PAID.value
            if not reservation.pnr:
                reservation.pnr = generate_pnr()
            from app.services.passenger_details_service import activate_ticket_after_passenger_details

            activate_ticket_after_passenger_details(reservation)

        if reservation is not None:
            locale = await _user_locale(db, payment.user_id)
            title, body = payment_success_copy(locale, payment.amount, payment.currency)
            await _dispatcher.dispatch(
                user_id=payment.user_id,
                event_type="payment_success",
                title=title,
                body=body,
                data={"payment_id": str(payment.id)},
                db=db,
            )
            logger.info("payment.completed", payment_id=payment.id)
    elif new_status == "failed":
        if payment.checkout_session_id is not None:
            session_result = await db.execute(
                select(CheckoutSession).where(CheckoutSession.id == payment.checkout_session_id),
            )
            session = session_result.scalar_one_or_none()
            if session is not None and session.status == CheckoutSessionStatus.OPEN.value:
                session.status = CheckoutSessionStatus.EXPIRED.value
        elif reservation is not None:
            reservation.status = ReservationStatus.CANCELED.value
            ticket_result = await db.execute(
                select(Ticket).where(Ticket.booking_id == reservation.id),
            )
            ticket = ticket_result.scalar_one_or_none()
            if ticket is not None:
                ticket.status = TicketStatus.CANCELED.value

        locale = await _user_locale(db, payment.user_id)
        title, body = payment_failed_copy(locale)
        await _dispatcher.dispatch(
            user_id=payment.user_id,
            event_type="payment_failed",
            title=title,
            body=body,
            data={"payment_id": str(payment.id)},
            db=db,
        )
        logger.warning("payment.failed", payment_id=payment.id)


@router.get("/payments/config", response_model=PaymentConfigResponse)
async def get_payment_config() -> PaymentConfigResponse:
    """Public payment configuration for the web checkout UI."""
    provider = active_payment_provider()
    return PaymentConfigResponse(
        provider=provider,
        publishable_key=settings.STRIPE_PUBLISHABLE_KEY if provider == "stripe" else None,
        stripe_test_mode=settings.stripe_test_mode if provider == "stripe" else False,
    )


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
    """Create a payment session for a checkout session."""
    result = await db.execute(
        select(CheckoutSession)
        .options(selectinload(CheckoutSession.flight))
        .where(CheckoutSession.id == body.checkout_session_id),
    )
    session = result.scalar_one_or_none()
    if session is None:
        raise HTTPException(status_code=404, detail="Checkout session not found")
    if session.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not your checkout session")
    if session.status != CheckoutSessionStatus.OPEN.value:
        raise HTTPException(status_code=409, detail="Checkout session is not open")
    if session.expires_at <= datetime.now(UTC):
        raise HTTPException(status_code=409, detail="Checkout session expired")
    if session.passengers_json is None:
        raise HTTPException(status_code=409, detail="Passenger details required before payment")

    amount = session.total_price or Decimal("0.00")
    currency = session.currency or "USD"
    provider = active_payment_provider()
    payment_service = get_payment_service()

    payment = Payment(
        checkout_session_id=session.id,
        reservation_id=None,
        user_id=user.id,
        provider=provider,
        provider_payment_id="pending",
        amount=amount,
        currency=currency,
        status="pending",
    )
    db.add(payment)
    await db.flush()

    try:
        session_data = await payment_service.create_session(
            amount=amount,
            currency=currency,
            reservation_id=session.id,
            user_id=user.id,
            payment_id=payment.id,
            locale=body.locale,
        )
    except Exception as exc:
        await db.rollback()
        logger.exception("payment.create_session_failed", checkout_session_id=session.id)
        if provider == "stripe":
            raise HTTPException(
                status_code=502,
                detail="Stripe payment session failed. Check STRIPE_SECRET_KEY or use PAYMENT_PROVIDER=mock.",
            ) from exc
        raise HTTPException(status_code=502, detail="Payment session failed") from exc

    payment.provider_payment_id = session_data["provider_payment_id"]
    await db.commit()
    await db.refresh(payment)

    checkout_url = session_data["checkout_url"]
    if provider == "mock":
        checkout_url = (
            f"{settings.WEB_APP_URL.rstrip('/')}/{body.locale}/book/payment-return"
            f"?checkout_session_id={session.id}"
            f"&payment_id={payment.id}"
            f"&mock=1"
        )

    return PaymentSessionResponse(
        payment_id=payment.id,
        session_id=session_data["session_id"],
        checkout_url=checkout_url,
        status=payment.status,
        provider=provider,
        publishable_key=settings.STRIPE_PUBLISHABLE_KEY if provider == "stripe" else None,
        stripe_test_mode=settings.stripe_test_mode if provider == "stripe" else False,
    )


@router.post("/payments/webhook")
async def payment_webhook(
    payload: PaymentWebhookPayload,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Handle mock payment provider callback."""
    if active_payment_provider() != "mock":
        raise HTTPException(status_code=404, detail="Use provider-specific webhook")

    payment_service = get_payment_service()
    verified = await payment_service.verify_webhook(payload.model_dump(), payload.signature)
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

    await _apply_payment_status(db, payment, new_status=payload.status)
    await db.commit()
    return {"status": "ok"}


@router.post("/payments/stripe/webhook")
async def stripe_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Stripe signed webhook (checkout.session.completed)."""
    if active_payment_provider() != "stripe":
        raise HTTPException(status_code=404, detail="Stripe is not enabled")

    raw_body = await request.body()
    signature = request.headers.get("stripe-signature")
    payment_service = get_payment_service()
    verified = await payment_service.verify_webhook(
        {"_raw_body": raw_body},
        signature,
    )
    if not verified.get("valid"):
        raise HTTPException(status_code=400, detail="Invalid Stripe webhook signature")
    if verified.get("ignored"):
        return {"status": "ignored", "event_type": verified.get("event_type")}

    provider_payment_id = verified.get("provider_payment_id")
    new_status = verified.get("status", "completed")
    if not provider_payment_id:
        return {"status": "ignored"}

    result = await db.execute(
        select(Payment).where(Payment.provider_payment_id == provider_payment_id)
    )
    payment = result.scalar_one_or_none()
    if payment is None:
        raise HTTPException(status_code=404, detail="Payment not found")

    await _apply_payment_status(db, payment, new_status=str(new_status))
    await db.commit()
    return {"status": "ok"}


@router.post("/payments/stripe/verify", response_model=PaymentRead)
async def verify_stripe_checkout(
    body: StripeVerifyRequest,
    user: User = Depends(require_permission("flights.read")),
    db: AsyncSession = Depends(get_db),
) -> PaymentRead:
    """Verify a Stripe Checkout session after redirect (local dev without webhook)."""
    if active_payment_provider() != "stripe":
        raise HTTPException(status_code=404, detail="Stripe is not enabled")

    result = await db.execute(
        select(Payment).where(Payment.provider_payment_id == body.session_id)
    )
    payment = result.scalar_one_or_none()
    if payment is None:
        raise HTTPException(status_code=404, detail="Payment not found")
    if payment.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not your payment")

    payment_service = get_payment_service()
    checkout = await payment_service.retrieve_checkout_session(body.session_id)
    await _apply_payment_status(db, payment, new_status=str(checkout["status"]))
    await db.commit()
    await db.refresh(payment)
    return PaymentRead.model_validate(payment)


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
    payment = await _load_owned_payment(payment_id, user, db)
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
    payment = await _load_owned_payment(payment_id, user, db)
    if payment.status != "completed":
        raise HTTPException(status_code=409, detail="Only completed payments can be refunded")

    payment_service = get_payment_service()
    await payment_service.refund(
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

    locale = await _user_locale(db, payment.user_id)
    title, body = payment_refunded_copy(locale, payment.amount, payment.currency)
    await _dispatcher.dispatch(
        user_id=payment.user_id,
        event_type="payment_refunded",
        title=title,
        body=body,
        data={"payment_id": str(payment.id)},
        db=db,
    )

    await db.commit()

    return RefundResponse(
        payment_id=payment.id,
        refund_status="refunded",
        refunded_amount=payment.amount,
    )
