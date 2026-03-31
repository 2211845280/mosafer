"""Ticket read API."""

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import get_current_user
from app.core.rbac import assert_user_has_permission, require_permission
from app.db.database import get_db
from app.models.reservations import Reservation
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User
from app.schemas.tickets import TicketRead, TicketReportResponse, TicketValidationResponse

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


@router.post(
    "/tickets/{ticket_number}/validate",
    response_model=TicketValidationResponse,
    dependencies=[Depends(require_permission("tickets.validate"))],
)
async def validate_ticket(
    ticket_number: str,
    db: AsyncSession = Depends(get_db),
) -> TicketValidationResponse:
    """Validate ticket number and mark as used when currently issued."""
    result = await db.execute(select(Ticket).where(Ticket.ticket_number == ticket_number.upper()))
    ticket = result.scalar_one_or_none()
    if ticket is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    if ticket.status == TicketStatus.CANCELLED.value:
        return TicketValidationResponse(ticket_number=ticket.ticket_number, valid=False, status=ticket.status)
    if ticket.status == TicketStatus.ISSUED.value:
        ticket.status = TicketStatus.USED.value
        await db.commit()
    return TicketValidationResponse(ticket_number=ticket.ticket_number, valid=True, status=ticket.status)


@router.get(
    "/tickets/history",
    response_model=list[TicketRead],
    dependencies=[Depends(require_permission("tickets.history.view"))],
)
async def list_ticket_history(
    db: AsyncSession = Depends(get_db),
    status_filter: str | None = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> list[TicketRead]:
    """List issued ticket history for reporting/auditing."""
    stmt = select(Ticket).order_by(Ticket.created_at.desc())
    if status_filter:
        stmt = stmt.where(Ticket.status == status_filter)
    stmt = stmt.offset(skip).limit(limit)
    rows = (await db.execute(stmt)).scalars().all()
    return [TicketRead.model_validate(row) for row in rows]


@router.get(
    "/tickets/report",
    response_model=TicketReportResponse,
    dependencies=[Depends(require_permission("tickets.report.view"))],
)
async def ticket_report(
    db: AsyncSession = Depends(get_db),
    from_date: datetime | None = Query(None),
    to_date: datetime | None = Query(None),
) -> TicketReportResponse:
    """Minimal issued/used/cancelled ticket counts."""
    issued_stmt = select(func.count()).select_from(Ticket).where(Ticket.status == TicketStatus.ISSUED.value)
    used_stmt = select(func.count()).select_from(Ticket).where(Ticket.status == TicketStatus.USED.value)
    cancelled_stmt = select(func.count()).select_from(Ticket).where(
        Ticket.status == TicketStatus.CANCELLED.value,
    )
    if from_date is not None:
        issued_stmt = issued_stmt.where(Ticket.created_at >= from_date)
        used_stmt = used_stmt.where(Ticket.created_at >= from_date)
        cancelled_stmt = cancelled_stmt.where(Ticket.created_at >= from_date)
    if to_date is not None:
        issued_stmt = issued_stmt.where(Ticket.created_at <= to_date)
        used_stmt = used_stmt.where(Ticket.created_at <= to_date)
        cancelled_stmt = cancelled_stmt.where(Ticket.created_at <= to_date)

    issued_count = (await db.execute(issued_stmt)).scalar_one()
    used_count = (await db.execute(used_stmt)).scalar_one()
    cancelled_count = (await db.execute(cancelled_stmt)).scalar_one()
    return TicketReportResponse(
        issued_count=issued_count,
        used_count=used_count,
        cancelled_count=cancelled_count,
    )
