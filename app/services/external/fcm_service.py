"""Firebase Cloud Messaging service.

Uses the real firebase-admin SDK. Falls back to logging if
credentials are missing.
"""

from __future__ import annotations

import asyncio
from functools import lru_cache

import structlog

from app.core.config import settings

logger = structlog.get_logger(__name__)

_firebase_initialised = False


def _ensure_firebase() -> bool:
    """Initialise the Firebase Admin SDK once. Returns True on success."""
    global _firebase_initialised
    if _firebase_initialised:
        return True

    if not settings.FIREBASE_CREDENTIALS_PATH:
        logger.warning("fcm.no_credentials_path")
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
        _firebase_initialised = True
        logger.info("fcm.initialised")
        return True
    except Exception:
        logger.exception("fcm.init_failed")
        return False


class FCMService:
    """Send push notifications via Firebase Cloud Messaging."""

    async def send_push(
        self,
        token: str,
        title: str,
        body: str,
        data: dict[str, str] | None = None,
    ) -> bool:
        if not _ensure_firebase():
            logger.warning("fcm.send_push.skipped", reason="not_initialised")
            return False

        try:
            from firebase_admin import messaging

            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                token=token,
            )
            response = await asyncio.to_thread(messaging.send, message)
            logger.info("fcm.send_push.ok", token=token[:12], response=response)
            return True
        except Exception:
            logger.exception("fcm.send_push.failed", token=token[:12])
            return False

    async def send_push_multi(
        self,
        tokens: list[str],
        title: str,
        body: str,
        data: dict[str, str] | None = None,
    ) -> int:
        """Send to multiple tokens. Returns count of successes."""
        if not tokens:
            return 0
        if not _ensure_firebase():
            logger.warning("fcm.send_multi.skipped", reason="not_initialised")
            return 0

        try:
            from firebase_admin import messaging

            message = messaging.MulticastMessage(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                tokens=tokens,
            )
            response = await asyncio.to_thread(messaging.send_each_for_multicast, message)
            successes = response.success_count
            logger.info("fcm.send_multi.ok", total=len(tokens), successes=successes)
            return successes
        except Exception:
            logger.exception("fcm.send_multi.failed")
            return 0


@lru_cache(maxsize=1)
def get_fcm_service() -> FCMService:
    return FCMService()
