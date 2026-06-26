"""Notification fan-out: in-app DB record + FCM push + Resend email.

Usage:
    dispatcher = NotificationDispatcher()
    await dispatcher.dispatch(
        user_id=42,
        event_type="payment_success",
        title="Payment Received",
        body="Your payment of $250 has been processed.",
        data={"payment_id": "123"},
        db=async_session,
    )
"""

from __future__ import annotations

from dataclasses import dataclass

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.device_tokens import DeviceToken
from app.models.notifications import Notification
from app.models.users import User
from app.services.external.email_service import get_email_service
from app.services.external.fcm_service import get_fcm_service

logger = structlog.get_logger(__name__)

_PUSH_EVENTS: set[str] = {
    "flight_update",
    "gate_change",
    "departure_reminder",
    "payment_success",
    "payment_failed",
    "payment_refunded",
    "trip_todo_14d",
    "trip_todo_7d",
    "trip_todo_3d",
    "trip_todo_1d",
    "trip_todo_6h",
    "trip_todo_3h",
    "flight_departure_6h",
    "home_departure_2h",
    "home_departure_30m",
    "home_departure_critical",
}

_EMAIL_EVENTS: set[str] = {
    "payment_success",
    "gate_change",
    "home_departure_critical",
}


@dataclass(frozen=True)
class NotificationDispatchResult:
    notification: Notification
    push_tokens: int = 0
    push_successes: int = 0


class NotificationDispatcher:
    """Fan out a notification to in-app, push, and email channels."""

    def __init__(self) -> None:
        self.fcm = get_fcm_service()
        self.email = get_email_service()

    async def dispatch(
        self,
        user_id: int,
        event_type: str,
        title: str,
        body: str,
        data: dict[str, str] | None = None,
        db: AsyncSession | None = None,
        force_push: bool = False,
    ) -> NotificationDispatchResult | None:
        if db is None:
            logger.error("dispatcher.no_db_session")
            return None

        notification = Notification(
            user_id=user_id,
            type=event_type,
            title=title,
            body=body,
        )
        db.add(notification)

        push_tokens = 0
        push_successes = 0
        if force_push or event_type in _PUSH_EVENTS:
            result = await db.execute(
                select(DeviceToken.token).where(DeviceToken.user_id == user_id)
            )
            tokens = [row[0] for row in result.all()]
            push_tokens = len(tokens)
            if tokens:
                push_successes = await self.fcm.send_push_multi(
                    tokens=tokens, title=title, body=body, data=data,
                )
                logger.info(
                    "dispatcher.push_sent",
                    user_id=user_id,
                    event_type=event_type,
                    tokens=len(tokens),
                    successes=push_successes,
                )

        if event_type in _EMAIL_EVENTS:
            user_result = await db.execute(
                select(User.email).where(User.id == user_id)
            )
            email = user_result.scalar_one_or_none()
            if email:
                sent = await self.email.send_email(
                    to=email,
                    subject=title,
                    html_body=f"<p>{body}</p>",
                )
                logger.info(
                    "dispatcher.email_sent",
                    user_id=user_id,
                    event_type=event_type,
                    success=sent,
                )

        return NotificationDispatchResult(
            notification=notification,
            push_tokens=push_tokens,
            push_successes=push_successes,
        )
