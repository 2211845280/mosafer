"""Ticket read API."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import get_current_user
from app.core.rbac import assert_user_has_permission, require_permission
from app.db.database import get_db
from app.models.reservations import Reservation
from app.models.tickets import Ticket
from app.models.users import User
from app.schemas.tickets import TicketRead

router = APIRouter()


@router.get(
    "/tickets/me",
    response_model=list[TicketRead],
    dependencies=[Depends(require_permission("tickets.view"))],
)
async def list_my_tickets(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[TicketRead]:
    """List tickets for reservations owned by the current user."""
    result = await db.execute(
        select(Ticket)
        .join(Reservation, Reservation.id == Ticket.reservation_id)
        .where(Reservation.user_id == user.id)
        .order_by(Ticket.created_at.desc()),
    )
    rows = result.scalars().all()
    return [TicketRead.model_validate(t) for t in rows]


@router.get(
    "/tickets/{ticket_number}",
    response_model=TicketRead,
)
async def get_ticket(
    ticket_number: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TicketRead:
    """Get ticket by ticket number (owner or admin)."""
    result = await db.execute(select(Ticket).where(Ticket.ticket_number == ticket_number.upper()))
    ticket = result.scalar_one_or_none()
    if ticket is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")

    res_r = await db.execute(select(Reservation).where(Reservation.id == ticket.reservation_id))
    reservation = res_r.scalar_one()
    if reservation.user_id != user.id:
        await assert_user_has_permission(db, user, "users.admin.manage")

    return TicketRead.model_validate(ticket)
