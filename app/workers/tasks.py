"""Background task functions.

Each task receives `ctx` (dict) as its first argument, which is populated
by ARQ with the worker's startup context (e.g. database session factory, redis).
"""

from __future__ import annotations

import structlog

logger = structlog.get_logger(__name__)


async def sample_task(ctx: dict, *, name: str = "world") -> str:
    """Minimal example task demonstrating the ARQ pattern."""
    logger.info("sample_task.started", name=name)
    result = f"Hello, {name}!"
    logger.info("sample_task.finished", result=result)
    return result
