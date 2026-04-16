"""Notification API router."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import get_current_user
from app.db.database import get_db
from app.models.notifications import Notification
from app.models.users import User
from app.schemas.notifications import NotificationMarkReadRequest, NotificationRead
from app.schemas.pagination import PaginatedResponse
from app.schemas.users import MessageResponse

router = APIRouter()


@router.get("/notifications", response_model=PaginatedResponse[NotificationRead])
async def list_notifications(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> PaginatedResponse[NotificationRead]:
    """List current user's notifications (newest first, paginated)."""
    base = select(Notification).where(Notification.user_id == current_user.id)
    total = (
        await db.execute(select(func.count()).select_from(base.subquery()))
    ).scalar_one()
    offset = (page - 1) * page_size
    result = await db.execute(
        base.order_by(Notification.created_at.desc()).offset(offset).limit(page_size)
    )
    items = [NotificationRead.model_validate(n) for n in result.scalars().all()]
    return PaginatedResponse.create(items=items, total=total, page=page, page_size=page_size)


@router.post("/notifications/read", response_model=MessageResponse)
async def mark_notifications_read(
    payload: NotificationMarkReadRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    """Mark specific notifications as read."""
    await db.execute(
        update(Notification)
        .where(
            Notification.user_id == current_user.id,
            Notification.id.in_(payload.ids),
        )
        .values(read=True)
    )
    await db.commit()
    return MessageResponse(message="Notifications marked as read")


@router.post("/notifications/read-all", response_model=MessageResponse)
async def mark_all_notifications_read(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    """Mark all of the current user's notifications as read."""
    await db.execute(
        update(Notification)
        .where(
            Notification.user_id == current_user.id,
            Notification.read.is_(False),
        )
        .values(read=True)
    )
    await db.commit()
    return MessageResponse(message="All notifications marked as read")
