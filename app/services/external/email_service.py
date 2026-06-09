"""SMTP email service for transactional emails.

Uses aiosmtplib. In development, Mailpit captures messages locally.
In production, configure Gmail SMTP (or any SMTP provider).
"""

from __future__ import annotations

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from functools import lru_cache

import aiosmtplib
import structlog

from app.core.config import settings

logger = structlog.get_logger(__name__)


class EmailService:
    """Send transactional emails via SMTP."""

    def __init__(self) -> None:
        self.from_email = settings.SMTP_FROM

    @staticmethod
    def _failure_reason(exc: Exception | None) -> str | None:
        if exc is None:
            return None
        msg = str(exc).lower()
        if "authentication" in msg or "535" in msg:
            return "smtp_auth"
        if "connection" in msg or "connect" in msg:
            return "smtp_connection"
        return "send_failed"

    async def _send_email_with_reason(
        self,
        to: str,
        subject: str,
        html_body: str,
    ) -> tuple[bool, str | None]:
        message = MIMEMultipart("alternative")
        message["From"] = self.from_email
        message["To"] = to
        message["Subject"] = subject
        message.attach(MIMEText(html_body, "html", "utf-8"))

        try:
            await aiosmtplib.send(
                message,
                hostname=settings.SMTP_HOST,
                port=settings.SMTP_PORT,
                username=settings.SMTP_USER,
                password=settings.SMTP_PASSWORD,
                use_tls=settings.SMTP_USE_TLS,
                start_tls=settings.SMTP_START_TLS,
            )
            logger.info("email.sent", to=to, subject=subject)
            return True, None
        except Exception as exc:
            reason = self._failure_reason(exc)
            logger.exception(
                "email.send_failed",
                to=to,
                subject=subject,
                failure_reason=reason,
            )
            return False, reason

    async def send_email(self, to: str, subject: str, html_body: str) -> bool:
        sent, _ = await self._send_email_with_reason(to, subject, html_body)
        return sent

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

    async def send_email_verification(self, to: str, verify_url: str) -> tuple[bool, str | None]:
        subject = "Verify your Mosafer email"
        html = f"""
        <h2>Verify your email</h2>
        <p>Thanks for signing up. Click the link below to verify your address:</p>
        <p><a href="{verify_url}">Verify email</a></p>
        <p>If you did not create an account, you can ignore this message.</p>
        """
        sent, reason = await self._send_email_with_reason(to, subject, html)
        if not sent:
            logger.warning(
                "email.verification.skipped",
                to=to,
                verify_url=verify_url,
                failure_reason=reason,
            )
        return sent, reason

    async def send_password_reset(self, to: str, reset_url: str) -> tuple[bool, str | None]:
        subject = "Reset your Mosafer password"
        html = f"""
        <h2>Reset your password</h2>
        <p>We received a request to reset your password. Click the link below:</p>
        <p><a href="{reset_url}">Reset password</a></p>
        <p>This link expires in {settings.PASSWORD_RESET_EXPIRE_MINUTES} minutes.</p>
        <p>If you did not request this, you can ignore this message.</p>
        """
        sent, reason = await self._send_email_with_reason(to, subject, html)
        if not sent:
            logger.warning(
                "email.password_reset.skipped",
                to=to,
                reset_url=reset_url,
                failure_reason=reason,
            )
        return sent, reason


@lru_cache(maxsize=1)
def get_email_service() -> EmailService:
    return EmailService()
