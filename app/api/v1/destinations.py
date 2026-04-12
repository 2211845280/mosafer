"""Destination intelligence endpoints."""

from __future__ import annotations

import structlog
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.cache import RedisCache, get_cache
from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.airports import Airport
from app.schemas.ai import DestinationTipsResult

logger = structlog.get_logger(__name__)

router = APIRouter()


@router.get(
    "/destinations/{iata}/tips",
    response_model=DestinationTipsResult,
    dependencies=[Depends(require_permission("flights.read"))],
)
async def get_destination_tips(
    iata: str,
    db: AsyncSession = Depends(get_db),
    cache: RedisCache = Depends(get_cache),
) -> DestinationTipsResult:
    """Get AI-generated travel tips for a destination (cached 7 days)."""
    iata_upper = iata.upper()
    cache_key = f"destination_tips:{iata_upper}"

    cached = await cache.get(cache_key)
    if cached is not None:
        logger.debug("destination_tips.cache_hit", iata=iata_upper)
        return DestinationTipsResult(**cached)

    result = await db.execute(
        select(Airport).where(Airport.iata_code == iata_upper)
    )
    airport = result.scalar_one_or_none()
    if airport is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Airport {iata_upper} not found",
        )

    from app.services.ai.prompts.destination_tips import build_tips_prompt

    system_prompt, user_message = build_tips_prompt(
        city=airport.city,
        country=airport.country,
        iata=iata_upper,
    )

    try:
        from app.services.ai.llm_client import get_llm_client

        client = get_llm_client()
        data = await client.chat_json(system_prompt, user_message)
        tips = DestinationTipsResult(**data)
    except Exception:
        logger.exception("destination_tips.llm_failed, returning empty")
        tips = DestinationTipsResult(
            visa=f"Check visa requirements for {airport.country}.",
            currency=f"Local currency used in {airport.country}.",
            language=f"Official language of {airport.country}.",
            general_tips=[f"Research {airport.city} before traveling."],
        )

    await cache.set(cache_key, tips.model_dump(mode="json"), ttl_seconds=604800)
    return tips
