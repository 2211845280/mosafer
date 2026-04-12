"""Health check API router."""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter
from sqlalchemy import text

from app.core.cache import redis_pool
from app.core.config import settings
from app.db.database import engine
from app.schemas.health import HealthComponentStatus, HealthResponse
from app.services.external.mock_flight_status_service import MockFlightStatusService

router = APIRouter()
_status_service = MockFlightStatusService()


@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Deep health check endpoint (DB + Redis + External)."""
    now = datetime.now(UTC)

    db_ok = True
    db_detail = "ok"
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception as exc:  # pragma: no cover - defensive branch
        db_ok = False
        db_detail = str(exc)

    redis_ok = True
    redis_detail = "ok"
    try:
        if redis_pool is None:
            raise RuntimeError("redis_pool is not initialized")
        await redis_pool.ping()
    except Exception as exc:  # pragma: no cover - defensive branch
        redis_ok = False
        redis_detail = str(exc)

    external_ok = True
    external_detail = "ok"
    try:
        await asyncio.wait_for(
            _status_service.get_status(
                carrier_code="MS",
                flight_number="100",
                departure_at=now + timedelta(hours=2),
            ),
            timeout=2.5,
        )
    except Exception as exc:  # pragma: no cover - defensive branch
        external_ok = False
        external_detail = str(exc)

    overall = "healthy" if all((db_ok, redis_ok, external_ok)) else "degraded"
    return HealthResponse(
        status=overall,
        environment=settings.ENVIRONMENT,
        db=HealthComponentStatus(name="db", ok=db_ok, detail=db_detail, checked_at=now),
        redis=HealthComponentStatus(name="redis", ok=redis_ok, detail=redis_detail, checked_at=now),
        external=HealthComponentStatus(
            name="external",
            ok=external_ok,
            detail=external_detail,
            checked_at=now,
        ),
    )
