"""Cancel reservations with optional refund based on departure proximity."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from decimal import ROUND_HALF_UP, Decimal
from typing import Literal

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.payments import Payment
from app.models.reservations import Reservation, ReservationStatus
from app.models.tickets import Ticket, TicketStatus
from app.services.external.mock_payment_service import MockPaymentService
from app.services.notification_dispatcher import NotificationDispatcher

_payment_service = MockPaymentService()
_dispatcher = NotificationDispatcher()

RefundType = Literal["none", "full", "partial"]


@dataclass
class CancelReservationResult:
    reservation: Reservation
    refunded_amount: Decimal | None
    penalty_amount: Decimal | None
    currency: str | None
    refund_type: RefundType


def _quantize(amount: Decimal) -> Decimal:
    return amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def days_until_departure(departure_at: datetime, now: datetime | None = None) -> int:
    """Calendar days from today (UTC) until departure date."""
    reference = now or datetime.now(UTC)
    if departure_at.tzinfo is None:
        departure_at = departure_at.replace(tzinfo=UTC)
    if reference.tzinfo is None:
        reference = reference.replace(tzinfo=UTC)
    return (departure_at.date() - reference.date()).days


def calculate_refund(
    total: Decimal,
    days_left: int,
) -> tuple[Decimal, Decimal, RefundType]:
    """Return (refund_amount, penalty_amount, refund_type)."""
    total = _quantize(total)
    if days_left > 3:
        return total, Decimal("0.00"), "full"
    refund = _quantize(total / 2)
    penalty = _quantize(total - refund)
    return refund, penalty, "partial"


def _notification_copy(
    locale: str,
    *,
    refund_type: RefundType,
    refunded: Decimal,
    penalty: Decimal,
    currency: str,
) -> tuple[str, str]:
    is_ar = locale.lower().startswith("ar")
    if refund_type == "none":
        if is_ar:
            return "تم إلغاء الحجز", "تم إلغاء حجزك بنجاح."
        return "Booking canceled", "Your booking has been canceled."

    if refund_type == "full":
        if is_ar:
            return (
                "استرداد كامل",
                f"تم إلغاء حجزك واسترداد {refunded} {currency} بالكامل.",
            )
        return (
            "Full refund",
            f"Your booking was canceled. {refunded} {currency} has been refunded in full.",
        )

    if is_ar:
        return (
            "استرداد جزئي",
            f"تم إلغاء حجزك. تم استرداد {refunded} {currency}. "
            f"تم خصم {penalty} {currency} لأن الإلغاء قبل 3 أيام أو أقل من المغادرة.",
        )
    return (
        "Partial refund",
        f"Your booking was canceled. {refunded} {currency} refunded. "
        f"A penalty of {penalty} {currency} was applied (departure within 3 days).",
    )


async def cancel_reservation_with_refund(
    db: AsyncSession,
    *,
    reservation_id: int,
    locale: str = "en",
) -> CancelReservationResult:
    result = await db.execute(
        select(Reservation)
        .options(selectinload(Reservation.flight))
        .where(Reservation.id == reservation_id),
    )
    reservation = result.scalar_one_or_none()
    if reservation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found")

    if reservation.status == ReservationStatus.CANCELED.value:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already cancelled")

    if reservation.flight is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Flight not found")

    days_left = days_until_departure(reservation.flight.departure_at)
    if days_left < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot cancel a past flight",
        )

    refunded_amount: Decimal | None = None
    penalty_amount: Decimal | None = None
    currency: str | None = reservation.currency
    refund_type: RefundType = "none"

    if reservation.status == ReservationStatus.PAID.value:
        payment_result = await db.execute(
            select(Payment)
            .where(
                Payment.reservation_id == reservation.id,
                Payment.status == "completed",
            )
            .order_by(Payment.id.desc()),
        )
        payment = payment_result.scalar_one_or_none()
        total = payment.amount if payment else reservation.total_price
        if total is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No payment amount found for this booking",
            )
        currency = payment.currency if payment else reservation.currency
        refund_amount, penalty, refund_type = calculate_refund(total, days_left)
        refunded_amount = refund_amount
        penalty_amount = penalty

        if payment is not None and refund_amount > 0:
            await _payment_service.refund(
                provider_payment_id=payment.provider_payment_id,
                amount=refund_amount,
            )
            payment.status = "refunded"

    reservation.status = ReservationStatus.CANCELED.value
    ticket_result = await db.execute(
        select(Ticket).where(Ticket.booking_id == reservation.id),
    )
    ticket = ticket_result.scalar_one_or_none()
    if ticket is not None:
        ticket.status = TicketStatus.CANCELED.value

    title, body = _notification_copy(
        locale,
        refund_type=refund_type,
        refunded=refunded_amount or Decimal("0.00"),
        penalty=penalty_amount or Decimal("0.00"),
        currency=currency or "USD",
    )
    await _dispatcher.dispatch(
        user_id=reservation.user_id,
        event_type="payment_refunded" if refund_type != "none" else "booking_canceled",
        title=title,
        body=body,
        data={"reservation_id": str(reservation.id)},
        db=db,
    )

    await db.commit()
    await db.refresh(reservation)

    return CancelReservationResult(
        reservation=reservation,
        refunded_amount=refunded_amount,
        penalty_amount=penalty_amount,
        currency=currency,
        refund_type=refund_type,
    )
