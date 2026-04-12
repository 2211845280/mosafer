"""Redis caching layer.

Provides a thin wrapper around ``redis.asyncio.Redis`` with JSON
serialisation, TTL support, and pattern-based cache invalidation.

The module-level ``redis_pool`` is initialised during application startup
and shared by the cache layer, ARQ worker connections, and rate limiting.
"""

from __future__ import annotations

import json
from typing import Any

import redis.asyncio as aioredis
import structlog

from app.core.config import settings

logger = structlog.get_logger(__name__)

redis_pool: aioredis.Redis | None = None


async def init_redis() -> aioredis.Redis:
    """Create the module-level Redis connection pool. Called during app startup."""
    global redis_pool
    redis_pool = aioredis.from_url(
        settings.REDIS_URL,
        decode_responses=True,
    )
    logger.info("redis.connected", url=settings.REDIS_URL)
    return redis_pool


async def close_redis() -> None:
    """Cleanly shut down the Redis connection. Called during app shutdown."""
    global redis_pool
    if redis_pool is not None:
        await redis_pool.aclose()
        redis_pool = None
        logger.info("redis.disconnected")


class RedisCache:
    """JSON-backed cache that wraps an ``aioredis.Redis`` connection."""

    def __init__(self, redis: aioredis.Redis) -> None:
        self._redis = redis

    async def get(self, key: str) -> Any | None:
        raw = await self._redis.get(key)
        if raw is None:
            return None
        try:
            return json.loads(raw)
        except (json.JSONDecodeError, TypeError):
            return raw

    async def set(self, key: str, value: Any, ttl_seconds: int = 300) -> None:
        await self._redis.set(key, json.dumps(value), ex=ttl_seconds)

    async def delete(self, key: str) -> None:
        await self._redis.delete(key)

    async def delete_pattern(self, pattern: str) -> int:
        """Remove all keys matching a glob *pattern*. Returns count deleted."""
        deleted = 0
        async for key in self._redis.scan_iter(match=pattern, count=100):
            await self._redis.delete(key)
            deleted += 1
        return deleted


async def get_cache() -> RedisCache:
    """FastAPI dependency that yields a ``RedisCache`` instance."""
    if redis_pool is None:
        raise RuntimeError("Redis has not been initialised. Call init_redis() first.")
    return RedisCache(redis_pool)
