"""Device token registration endpoints for FCM push notifications."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import get_current_user
from app.db.database import get_db
from app.models.device_tokens import DeviceToken
from app.models.users import User

router = APIRouter()


class DeviceRegisterRequest(BaseModel):
    token: str
    platform: str = "android"


class DeviceRegisterResponse(BaseModel):
    id: int
    token: str
    platform: str


@router.post(
    "/devices/register",
    response_model=DeviceRegisterResponse,
    status_code=status.HTTP_201_CREATED,
)
async def register_device(
    body: DeviceRegisterRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DeviceRegisterResponse:
    """Register or update a device token for push notifications."""
    result = await db.execute(
        select(DeviceToken).where(DeviceToken.token == body.token)
    )
    existing = result.scalar_one_or_none()

    if existing:
        existing.user_id = user.id
        existing.platform = body.platform
        await db.commit()
        await db.refresh(existing)
        return DeviceRegisterResponse(
            id=existing.id, token=existing.token, platform=existing.platform,
        )

    device = DeviceToken(
        user_id=user.id,
        token=body.token,
        platform=body.platform,
    )
    db.add(device)
    await db.commit()
    await db.refresh(device)
    return DeviceRegisterResponse(
        id=device.id, token=device.token, platform=device.platform,
    )


@router.delete(
    "/devices/{token}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def unregister_device(
    token: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Remove a device token."""
    result = await db.execute(
        select(DeviceToken).where(
            DeviceToken.token == token,
            DeviceToken.user_id == user.id,
        )
    )
    device = result.scalar_one_or_none()
    if device is None:
        raise HTTPException(status_code=404, detail="Device token not found")
    await db.delete(device)
    await db.commit()
