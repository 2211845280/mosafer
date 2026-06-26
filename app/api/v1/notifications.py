"""Notification API router."""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import get_current_user
from app.core.rbac import assert_user_has_permission
from app.db.database import get_db
from app.models.notifications import Notification
from app.models.users import User
from app.schemas.notifications import (
    NotificationMarkReadRequest,
    NotificationRead,
    NotificationSendRequest,
    NotificationSendResponse,
)
from app.schemas.pagination import PaginatedResponse
from app.schemas.users import MessageResponse
from app.services.notification_dispatcher import NotificationDispatcher

router = APIRouter()
_dispatcher = NotificationDispatcher()


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


@router.post("/notifications/send", response_model=NotificationSendResponse)
async def send_notification(
    payload: NotificationSendRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> NotificationSendResponse:
    """Create an in-app notification and send it as an FCM push notification."""
    target_user_id = payload.target_user_id or current_user.id
    if target_user_id != current_user.id:
        await assert_user_has_permission(db, current_user, "users.admin.manage")
        target = (
            await db.execute(select(User.id).where(User.id == target_user_id))
        ).scalar_one_or_none()
        if target is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    dispatch_result = await _dispatcher.dispatch(
        user_id=target_user_id,
        event_type=payload.type,
        title=payload.title,
        body=payload.body,
        data=payload.data,
        db=db,
        force_push=True,
    )
    if dispatch_result is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Notification could not be created",
        )

    await db.commit()
    notification = dispatch_result.notification
    await db.refresh(notification)
    return NotificationSendResponse(
        notification=NotificationRead.model_validate(notification),
        push_requested=True,
        push_tokens=dispatch_result.push_tokens,
        push_successes=dispatch_result.push_successes,
    )


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


@router.delete("/notifications/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_notification(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Delete a notification owned by the current user."""
    result = await db.execute(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
        )
    )
    notification = result.scalar_one_or_none()
    if notification is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    await db.execute(delete(Notification).where(Notification.id == notification_id))
    await db.commit()
