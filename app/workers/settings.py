"""ARQ worker settings.

Run the worker with:
    arq app.workers.settings.WorkerSettings
"""

from __future__ import annotations

import structlog
from arq.connections import RedisSettings
from arq.cron import cron

from app.core.config import settings
from app.workers.departure_alert import check_departure_alerts
from app.workers.flight_status_poller import poll_flight_statuses
from app.workers.tasks import sample_task

logger = structlog.get_logger(__name__)


def _parse_redis_url(url: str) -> RedisSettings:
    """Convert a redis:// URL into ARQ RedisSettings."""
    from urllib.parse import urlparse

    parsed = urlparse(url)
    return RedisSettings(
        host=parsed.hostname or "localhost",
        port=parsed.port or 6379,
        database=int(parsed.path.lstrip("/") or 0),
        password=parsed.password,
    )


async def on_startup(ctx: dict) -> None:
    import redis.asyncio as aioredis

    from app.db.database import AsyncSessionLocal

    ctx["db"] = AsyncSessionLocal
    ctx["redis"] = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
    logger.info("arq_worker.startup")


async def on_shutdown(ctx: dict) -> None:
    redis_conn = ctx.get("redis")
    if redis_conn:
        await redis_conn.aclose()
    logger.info("arq_worker.shutdown")


class WorkerSettings:
    functions = [sample_task, poll_flight_statuses, check_departure_alerts]
    cron_jobs = [
        cron(poll_flight_statuses, minute={m for m in range(0, 60, 3)}),
        cron(check_departure_alerts, minute={0, 30}),
    ]
    redis_settings = _parse_redis_url(settings.REDIS_URL)
    on_startup = on_startup
    on_shutdown = on_shutdown
    max_jobs = 10
    job_timeout = 300
