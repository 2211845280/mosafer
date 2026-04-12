"""API v2 health endpoint."""

from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health_v2() -> dict[str, str]:
    """v2-compatible health probe."""
    return {
        "status": "healthy",
        "api_version": "v2",
    }
