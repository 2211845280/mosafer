"""Resend email service for transactional emails.

Uses the real Resend Python SDK. Falls back to logging when
RESEND_API_KEY is not configured.
"""

from __future__ import annotations

import asyncio
from functools import lru_cache

import structlog

from app.core.config import settings

logger = structlog.get_logger(__name__)

_resend_ready = False


def _ensure_resend() -> bool:
    global _resend_ready
    if _resend_ready:
        return True

    if not settings.RESEND_API_KEY:
        logger.warning("email.no_api_key")
        return False

    try:
        import resend

        resend.api_key = settings.RESEND_API_KEY
        _resend_ready = True
        logger.info("email.resend_initialised")
        return True
    except Exception:
        logger.exception("email.resend_init_failed")
        return False


class EmailService:
    """Send transactional emails via Resend."""

    def __init__(self) -> None:
        self.from_email = settings.RESEND_FROM_EMAIL

    async def send_email(self, to: str, subject: str, html_body: str) -> bool:
        if not _ensure_resend():
            logger.warning("email.send.skipped", to=to, subject=subject)
            return False

        try:
            import resend

            params = {
                "from_": self.from_email,
                "to": [to],
                "subject": subject,
                "html": html_body,
            }
            response = await asyncio.to_thread(resend.Emails.send, params)
            logger.info("email.sent", to=to, response_id=response.get("id") if isinstance(response, dict) else str(response))
            return True
        except Exception:
            logger.exception("email.send_failed", to=to, subject=subject)
            return False

    async def send_booking_confirmation(
        self,
        to: str,
        reservation_id: int,
        flight_label: str,
        departure: str,
    ) -> bool:
        subject = f"Booking Confirmed — {flight_label}"
        html = f"""
        <h2>Your booking is confirmed!</h2>
        <p><strong>Reservation:</strong> #{reservation_id}</p>
        <p><strong>Flight:</strong> {flight_label}</p>
        <p><strong>Departure:</strong> {departure}</p>
        <p>Open the Mosafer app for full details and your boarding QR code.</p>
        """
        return await self.send_email(to, subject, html)

    async def send_payment_receipt(
        self,
        to: str,
        amount: str,
        currency: str,
        payment_id: int,
    ) -> bool:
        subject = "Payment Receipt — Mosafer"
        html = f"""
        <h2>Payment Received</h2>
        <p><strong>Amount:</strong> {amount} {currency}</p>
        <p><strong>Payment ID:</strong> #{payment_id}</p>
        <p>Thank you for your purchase on Mosafer.</p>
        """
        return await self.send_email(to, subject, html)

    async def send_trip_reminder(
        self,
        to: str,
        flight_label: str,
        departure: str,
    ) -> bool:
        subject = f"Trip Reminder — {flight_label}"
        html = f"""
        <h2>Upcoming Flight</h2>
        <p><strong>Flight:</strong> {flight_label}</p>
        <p><strong>Departure:</strong> {departure}</p>
        <p>Don't forget to check your packing list in the Mosafer app!</p>
        """
        return await self.send_email(to, subject, html)


@lru_cache(maxsize=1)
def get_email_service() -> EmailService:
    return EmailService()
