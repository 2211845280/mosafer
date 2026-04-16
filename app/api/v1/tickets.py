"""Ticket API (Epic 3 — local ticketing)."""

import json
from datetime import datetime
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from fastapi.responses import Response
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.file_validation import has_valid_magic_bytes
from app.core.jwt import get_current_user
from app.core.rbac import assert_user_has_permission, require_permission
from app.core.ticket_pdf import build_ticket_pdf_bytes
from app.db.database import get_db
from app.models.reservations import Reservation
from app.models.tickets import Ticket, TicketImage, TicketStatus
from app.models.users import User
from app.schemas.pagination import PaginatedResponse
from app.schemas.tickets import (
    FlightSummaryForTicket,
    QRScanRequest,
    QRScanResponse,
    TicketListItem,
    TicketRead,
    TicketReportResponse,
    TicketValidationResponse,
    ticket_list_item,
)

router = APIRouter()


async def _fetch_user_ticket_page(
    db: AsyncSession,
    user_id: int,
    *,
    page: int,
    page_size: int,
) -> PaginatedResponse[TicketListItem]:
    total = (
        await db.execute(
            select(func.count())
            .select_from(Ticket)
            .join(Reservation, Reservation.id == Ticket.booking_id)
            .where(Reservation.user_id == user_id)
        )
    ).scalar_one()
    offset = (page - 1) * page_size
    result = await db.execute(
        select(Ticket)
        .join(Reservation, Reservation.id == Ticket.booking_id)
        .options(selectinload(Ticket.booking).selectinload(Reservation.flight))
        .where(Reservation.user_id == user_id)
        .order_by(Ticket.issued_at.desc())
        .offset(offset)
        .limit(page_size),
    )
    items = [ticket_list_item(t) for t in result.scalars().all()]
    return PaginatedResponse.create(items=items, total=total, page=page, page_size=page_size)


async def _load_ticket_for_user(
    db: AsyncSession,
    ticket_id: int,
    user: User,
) -> Ticket:
    result = await db.execute(
        select(Ticket)
        .options(selectinload(Ticket.booking).selectinload(Reservation.flight))
        .where(Ticket.id == ticket_id),
    )
    ticket = result.scalar_one_or_none()
    if ticket is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    if ticket.booking.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your ticket")
    return ticket


@router.get(
    "/tickets",
    response_model=PaginatedResponse[TicketListItem],
    dependencies=[Depends(require_permission("tickets.view"))],
)
async def list_my_tickets(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
) -> PaginatedResponse[TicketListItem]:
    """List authenticated user's tickets with flight summary."""
    return await _fetch_user_ticket_page(db, user.id, page=page, page_size=page_size)


@router.get(
    "/tickets/me",
    response_model=PaginatedResponse[TicketListItem],
    dependencies=[Depends(require_permission("tickets.view"))],
)
async def list_my_tickets_legacy(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
) -> PaginatedResponse[TicketListItem]:
    """Backward-compatible alias for GET /tickets."""
    return await _fetch_user_ticket_page(db, user.id, page=page, page_size=page_size)


@router.get(
    "/tickets/history",
    response_model=PaginatedResponse[TicketListItem],
    dependencies=[Depends(require_permission("tickets.view"))],
)
async def list_ticket_history(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    status_filter: str | None = Query(None),
    from_date: datetime | None = Query(None),
    to_date: datetime | None = Query(None),
    user_id: int | None = Query(None, description="Admin only: filter by user"),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
) -> PaginatedResponse[TicketListItem]:
    """Ticket history for current user; admin may pass user_id."""
    target_user_id = user.id
    if user_id is not None and user_id != user.id:
        await assert_user_has_permission(db, user, "users.admin.manage")
        target_user_id = user_id

    base = (
        select(Ticket)
        .join(Reservation, Reservation.id == Ticket.booking_id)
        .where(Reservation.user_id == target_user_id)
    )
    if status_filter:
        base = base.where(Ticket.status == status_filter)
    if from_date is not None:
        base = base.where(Ticket.issued_at >= from_date)
    if to_date is not None:
        base = base.where(Ticket.issued_at <= to_date)

    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    offset = (page - 1) * page_size
    data_stmt = (
        base.options(selectinload(Ticket.booking).selectinload(Reservation.flight))
        .order_by(Ticket.issued_at.desc())
        .offset(offset)
        .limit(page_size)
    )
    rows = (await db.execute(data_stmt)).scalars().all()
    items = [ticket_list_item(t) for t in rows]
    return PaginatedResponse.create(items=items, total=total, page=page, page_size=page_size)


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
    """Aggregated ticket counts (admin)."""
    filters = []
    if from_date is not None:
        filters.append(Ticket.issued_at >= from_date)
    if to_date is not None:
        filters.append(Ticket.issued_at <= to_date)

    total_stmt = select(func.count()).select_from(Ticket)
    if filters:
        total_stmt = total_stmt.where(*filters)
    total = (await db.execute(total_stmt)).scalar_one()

    async def count_status(st: str) -> int:
        q = select(func.count()).select_from(Ticket).where(Ticket.status == st)
        if filters:
            q = q.where(*filters)
        return (await db.execute(q)).scalar_one()

    valid_c = await count_status(TicketStatus.VALID.value)
    used_c = await count_status(TicketStatus.USED.value)
    canceled_c = await count_status(TicketStatus.CANCELED.value)

    return TicketReportResponse(
        total_tickets=total,
        valid_count=valid_c,
        used_count=used_c,
        canceled_count=canceled_c,
    )


@router.get(
    "/tickets/{ticket_id}/download",
    dependencies=[Depends(require_permission("tickets.download"))],
)
async def download_ticket_pdf(
    ticket_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Response:
    """Download ticket as PDF (QR + booking details)."""
    ticket = await _load_ticket_for_user(db, ticket_id, user)
    b = ticket.booking
    f = b.flight
    pdf_bytes = build_ticket_pdf_bytes(
        ticket_number=ticket.ticket_number,
        booking_id=ticket.booking_id,
        seat=b.seat,
        carrier_code=f.carrier_code,
        flight_number=f.flight_number,
        origin_iata=f.origin_iata,
        destination_iata=f.destination_iata,
        departure_at=f.departure_at.isoformat(),
        arrival_at=f.arrival_at.isoformat(),
        qr_image_relative=ticket.qr_image_path,
    )
    filename = f"ticket_{ticket.ticket_number}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.post(
    "/tickets/{ticket_id}/upload",
    dependencies=[Depends(require_permission("tickets.upload"))],
    status_code=status.HTTP_201_CREATED,
)
async def upload_ticket_image(
    ticket_id: int,
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, str]:
    """Attach a file to a ticket (documents, images)."""
    ticket = await _load_ticket_for_user(db, ticket_id, user)

    allowed = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
        "application/pdf": ".pdf",
    }
    if file.content_type not in allowed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file type",
        )
    content = await file.read()
    if len(content) > settings.TICKET_UPLOAD_MAX_SIZE_BYTES:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="File too large")
    if not has_valid_magic_bytes(content, file.content_type):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File content does not match declared type",
        )

    base_dir = Path(settings.TICKET_UPLOADS_DIR)
    base_dir.mkdir(parents=True, exist_ok=True)
    fname = f"{ticket_id}_{uuid4().hex}{allowed[file.content_type]}"
    path = base_dir / fname
    path.write_bytes(content)

    img = TicketImage(ticket_id=ticket.id, file_path=path.as_posix())
    db.add(img)
    await db.commit()
    return {"message": "Upload saved", "file_path": img.file_path}


@router.post(
    "/tickets/{ticket_number}/validate",
    response_model=TicketValidationResponse,
    dependencies=[Depends(require_permission("tickets.validate"))],
)
async def validate_ticket(
    ticket_number: str,
    db: AsyncSession = Depends(get_db),
) -> TicketValidationResponse:
    """Validate QR/ticket number: valid→used; used→already_used; canceled→invalid."""
    tn = ticket_number.strip().upper()
    result = await db.execute(select(Ticket).where(Ticket.ticket_number == tn))
    ticket = result.scalar_one_or_none()
    if ticket is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket not found",
        )

    if ticket.status == TicketStatus.CANCELED.value:
        return TicketValidationResponse(
            ticket_number=ticket.ticket_number,
            status=ticket.status,
            ok=False,
            code="invalid",
            message="Ticket is canceled",
        )

    if ticket.status == TicketStatus.USED.value:
        return TicketValidationResponse(
            ticket_number=ticket.ticket_number,
            status=ticket.status,
            ok=False,
            code="already_used",
            message="Ticket was already used",
        )

    if ticket.status == TicketStatus.VALID.value:
        ticket.status = TicketStatus.USED.value
        await db.commit()
        await db.refresh(ticket)
        return TicketValidationResponse(
            ticket_number=ticket.ticket_number,
            status=ticket.status,
            ok=True,
            code="validated",
            message="Ticket validated successfully",
        )

    return TicketValidationResponse(
        ticket_number=ticket.ticket_number,
        status=ticket.status,
        ok=False,
        code="invalid",
        message="Ticket cannot be validated",
    )


@router.get(
    "/tickets/{ticket_number}",
    response_model=TicketRead,
    dependencies=[Depends(require_permission("tickets.view"))],
)
async def get_ticket(
    ticket_number: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TicketRead:
    """Get ticket by ticket number (owner or admin)."""
    result = await db.execute(
        select(Ticket).where(Ticket.ticket_number == ticket_number.strip().upper())
    )
    ticket = result.scalar_one_or_none()
    if ticket is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")

    res_r = await db.execute(select(Reservation).where(Reservation.id == ticket.booking_id))
    reservation = res_r.scalar_one()
    if reservation.user_id != user.id:
        await assert_user_has_permission(db, user, "users.admin.manage")

    return TicketRead.model_validate(ticket)


@router.post(
    "/tickets/scan",
    response_model=QRScanResponse,
    dependencies=[Depends(require_permission("tickets.view"))],
)
async def scan_ticket_qr(
    data: QRScanRequest,
    db: AsyncSession = Depends(get_db),
) -> QRScanResponse:
    """Parse a QR payload and return full ticket + flight data.

    Accepts both the new JSON format and the legacy plain ticket-number format.
    """
    raw = data.qr_payload.strip()

    try:
        payload = json.loads(raw)
        ticket_number = payload.get("ticket_number", "").strip().upper()
    except (json.JSONDecodeError, AttributeError):
        ticket_number = raw.upper()

    if not ticket_number:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="QR payload does not contain a ticket number",
        )

    result = await db.execute(
        select(Ticket)
        .options(selectinload(Ticket.booking).selectinload(Reservation.flight))
        .where(Ticket.ticket_number == ticket_number),
    )
    ticket = result.scalar_one_or_none()
    if ticket is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket not found",
        )

    booking = ticket.booking
    flight = booking.flight

    return QRScanResponse(
        ticket_number=ticket.ticket_number,
        ticket_status=ticket.status,
        reservation_id=booking.id,
        reservation_status=booking.status,
        flight=FlightSummaryForTicket(
            carrier_code=flight.carrier_code,
            flight_number=flight.flight_number,
            origin_iata=flight.origin_iata,
            destination_iata=flight.destination_iata,
            departure_at=flight.departure_at,
            arrival_at=flight.arrival_at,
            seat=booking.seat,
        ),
        issued_at=ticket.issued_at,
    )
