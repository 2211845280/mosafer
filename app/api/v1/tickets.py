"""Ticket API (Epic 3 — local ticketing)."""

import json
from datetime import UTC, datetime, timedelta
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from fastapi.responses import Response
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.file_validation import has_valid_magic_bytes
from app.core.jwt import get_current_user
from app.core.rbac import assert_user_has_permission, require_permission
from app.core.ticket_numbers import compact_ticket_number, ticket_number_candidates
from app.core.ticket_pdf import build_ticket_pdf_bytes
from app.data.airlines import carrier_name
from app.db.database import get_db
from app.models.booking_passengers import BookingPassenger
from app.models.reservations import Reservation
from app.models.tickets import Ticket, TicketImage, TicketStatus
from app.models.users import User
from app.schemas.pagination import PaginatedResponse
from app.schemas.tickets import (
    FlightSummaryForTicket,
    QRScanRequest,
    QRScanResponse,
    TicketClaimRequest,
    TicketClaimResponse,
    TicketImageDBMatch,
    TicketImageScanResponse,
    TicketListItem,
    TicketRead,
    TicketReportResponse,
    TicketValidationResponse,
    ticket_list_item,
)
from app.services.ai.ticket_image_analyzer import analyze_ticket_image

router = APIRouter()


def _normalized_ticket_number_column():
    expr = func.upper(Ticket.ticket_number)
    for separator in ("-", " ", ".", "/"):
        expr = func.replace(expr, separator, "")
    return expr


def _normalized_passenger_ticket_number_column():
    expr = func.upper(BookingPassenger.passenger_ticket_number)
    for separator in ("-", " ", ".", "/"):
        expr = func.replace(expr, separator, "")
    return expr


def _extract_ticket_number(value: str) -> str:
    raw = value.strip()
    if not raw:
        return ""
    try:
        payload = json.loads(raw)
        if isinstance(payload, dict):
            return str(payload.get("ticket_number", "")).strip().upper()
    except json.JSONDecodeError:
        pass
    return raw.upper()


async def _find_ticket_by_number(
    db: AsyncSession,
    ticket_number: str,
    *,
    with_booking: bool = False,
) -> Ticket | None:
    candidates = ticket_number_candidates(ticket_number)
    compact = compact_ticket_number(ticket_number)
    conditions = []
    if candidates:
        conditions.append(Ticket.ticket_number.in_(candidates))
    if compact:
        conditions.append(_normalized_ticket_number_column() == compact)
    if not conditions:
        return None

    stmt = select(Ticket).where(or_(*conditions))
    if with_booking:
        stmt = stmt.options(
            selectinload(Ticket.booking).selectinload(Reservation.flight),
        )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def _find_passenger_by_ticket_number(
    db: AsyncSession,
    ticket_number: str,
) -> BookingPassenger | None:
    candidates = ticket_number_candidates(ticket_number)
    compact = compact_ticket_number(ticket_number)
    conditions = []
    if candidates:
        conditions.append(BookingPassenger.passenger_ticket_number.in_(candidates))
    if compact:
        conditions.append(_normalized_passenger_ticket_number_column() == compact)
    if not conditions:
        return None

    result = await db.execute(
        select(BookingPassenger)
        .options(
            selectinload(BookingPassenger.reservation).selectinload(Reservation.flight),
            selectinload(BookingPassenger.reservation).selectinload(Reservation.ticket),
        )
        .where(or_(*conditions)),
    )
    return result.scalar_one_or_none()


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
        .options(
            selectinload(Ticket.booking).selectinload(Reservation.flight),
            selectinload(Ticket.booking).selectinload(Reservation.passengers),
        )
        .where(Ticket.id == ticket_id),
    )
    ticket = result.scalar_one_or_none()
    if ticket is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    if ticket.booking.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your ticket")
    return ticket


def _to_db_match(ticket: Ticket) -> TicketImageDBMatch:
    booking = ticket.booking
    flight = booking.flight
    return TicketImageDBMatch(
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


def _to_db_match_from_passenger(passenger: BookingPassenger) -> TicketImageDBMatch:
    booking = passenger.reservation
    flight = booking.flight
    ticket = booking.ticket
    return TicketImageDBMatch(
        ticket_number=passenger.passenger_ticket_number or ticket.ticket_number,
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
            seat=passenger.seat or booking.seat,
        ),
        issued_at=ticket.issued_at,
    )


def _scan_response_from_ticket(ticket: Ticket) -> QRScanResponse:
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


def _scan_response_from_passenger(passenger: BookingPassenger) -> QRScanResponse:
    booking = passenger.reservation
    ticket = booking.ticket
    if ticket is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    flight = booking.flight
    return QRScanResponse(
        ticket_number=passenger.passenger_ticket_number or ticket.ticket_number,
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
            seat=passenger.seat or booking.seat,
        ),
        issued_at=ticket.issued_at,
    )


def _claim_response(
    *,
    claimed: bool,
    ticket_number: str,
    reservation: Reservation,
    assigned_to_user_id: int,
    scope: str,
    message: str,
    seat: str,
) -> TicketClaimResponse:
    flight = reservation.flight
    return TicketClaimResponse(
        claimed=claimed,
        ticket_number=ticket_number,
        reservation_id=reservation.id,
        assigned_to_user_id=assigned_to_user_id,
        scope=scope,
        message=message,
        flight=FlightSummaryForTicket(
            carrier_code=flight.carrier_code,
            flight_number=flight.flight_number,
            origin_iata=flight.origin_iata,
            destination_iata=flight.destination_iata,
            departure_at=flight.departure_at,
            arrival_at=flight.arrival_at,
            seat=seat,
        ),
    )


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
    if ticket.status == TicketStatus.PENDING_PASSENGER.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Complete passenger and passport details before downloading your e-ticket",
        )
    b = ticket.booking
    f = b.flight
    passenger_name = None
    if b.passengers:
        primary = sorted(b.passengers, key=lambda p: p.sequence)[0]
        passenger_name = f"{primary.family_name}/{primary.given_name}"
    pdf_bytes = build_ticket_pdf_bytes(
        ticket_number=ticket.ticket_number,
        booking_id=ticket.booking_id,
        seat=b.seat,
        carrier_code=f.carrier_code,
        carrier_name=carrier_name(f.carrier_code),
        flight_number=f.flight_number,
        origin_iata=f.origin_iata,
        destination_iata=f.destination_iata,
        departure_at=f.departure_at.isoformat(),
        arrival_at=f.arrival_at.isoformat(),
        qr_image_relative=ticket.qr_image_path,
        pnr=b.pnr,
        passenger_name=passenger_name,
        cabin_class=b.cabin_class,
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
    ticket = await _find_ticket_by_number(db, ticket_number)
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
    ticket = await _find_ticket_by_number(db, ticket_number)
    if ticket is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")

    res_r = await db.execute(select(Reservation).where(Reservation.id == ticket.booking_id))
    reservation = res_r.scalar_one()
    if reservation.user_id != user.id:
        await assert_user_has_permission(db, user, "users.admin.manage")

    return TicketRead.model_validate(ticket)


@router.post(
    "/tickets/claim",
    response_model=TicketClaimResponse,
    dependencies=[Depends(require_permission("tickets.view"))],
)
async def claim_ticket(
    data: TicketClaimRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TicketClaimResponse:
    """Permanently link a QR ticket to the current user's account."""
    ticket_number = _extract_ticket_number(data.ticket_number)
    if not ticket_number:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ticket number is required",
        )

    passenger = await _find_passenger_by_ticket_number(db, ticket_number)
    if passenger is not None:
        reservation = passenger.reservation
        if passenger.ordered_by_user_id is None:
            passenger.ordered_by_user_id = reservation.user_id
        if passenger.assigned_to_user_id is not None:
            if passenger.assigned_to_user_id != user.id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Ticket is already assigned to another account",
                )
            return _claim_response(
                claimed=False,
                ticket_number=passenger.passenger_ticket_number or ticket_number,
                reservation=reservation,
                assigned_to_user_id=user.id,
                scope="passenger",
                message="Ticket is already assigned to this account",
                seat=passenger.seat or reservation.seat,
            )

        passenger.assigned_to_user_id = user.id
        await db.commit()
        return _claim_response(
            claimed=True,
            ticket_number=passenger.passenger_ticket_number or ticket_number,
            reservation=reservation,
            assigned_to_user_id=user.id,
            scope="passenger",
            message="Ticket assigned to this account",
            seat=passenger.seat or reservation.seat,
        )

    ticket = await _find_ticket_by_number(db, ticket_number, with_booking=True)
    if ticket is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")

    reservation = ticket.booking
    if ticket.ordered_by_user_id is None:
        ticket.ordered_by_user_id = reservation.user_id
    if ticket.assigned_to_user_id is not None:
        if ticket.assigned_to_user_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Ticket is already assigned to another account",
            )
        return _claim_response(
            claimed=False,
            ticket_number=ticket.ticket_number,
            reservation=reservation,
            assigned_to_user_id=user.id,
            scope="ticket",
            message="Ticket is already assigned to this account",
            seat=reservation.seat,
        )

    ticket.assigned_to_user_id = user.id
    await db.commit()
    return _claim_response(
        claimed=True,
        ticket_number=ticket.ticket_number,
        reservation=reservation,
        assigned_to_user_id=user.id,
        scope="ticket",
        message="Ticket assigned to this account",
        seat=reservation.seat,
    )


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
    ticket_number = _extract_ticket_number(data.qr_payload)
    if not ticket_number:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="QR payload does not contain a ticket number",
        )

    passenger = await _find_passenger_by_ticket_number(db, ticket_number)
    if passenger is not None:
        return _scan_response_from_passenger(passenger)

    ticket = await _find_ticket_by_number(db, ticket_number, with_booking=True)
    if ticket is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket not found",
        )

    return _scan_response_from_ticket(ticket)


@router.post(
    "/tickets/scan-image",
    response_model=TicketImageScanResponse,
    dependencies=[Depends(require_permission("tickets.view"))],
)
async def scan_ticket_image(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
) -> TicketImageScanResponse:
    """Analyze a ticket image, warn invalid/expired, and return extracted data."""
    allowed = {"image/jpeg", "image/png", "image/webp"}
    if file.content_type not in allowed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file type",
        )

    content = await file.read()
    if len(content) > settings.TICKET_IMAGE_ANALYSIS_MAX_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File too large",
        )
    if not has_valid_magic_bytes(content, file.content_type):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File content does not match declared type",
        )

    analysis = await analyze_ticket_image(content, file.content_type)
    warnings = list(analysis.warnings)

    if not analysis.looks_like_ticket:
        if not warnings:
            warnings.append("This image does not look like a valid ticket.")
        return TicketImageScanResponse(
            decision="invalid_ticket",
            warnings=warnings,
            normalized_ticket_number=analysis.normalized_ticket_number,
            extracted_fields=analysis.extracted_fields,
            field_confidence=analysis.field_confidence,
            raw_text=analysis.raw_text,
        )

    if not analysis.normalized_ticket_number:
        warnings.append("Ticket number could not be detected from the image.")
        return TicketImageScanResponse(
            decision="invalid_ticket",
            warnings=warnings,
            normalized_ticket_number=None,
            extracted_fields=analysis.extracted_fields,
            field_confidence=analysis.field_confidence,
            raw_text=analysis.raw_text,
        )

    passenger = await _find_passenger_by_ticket_number(db, analysis.normalized_ticket_number)
    ticket = None
    if passenger is not None:
        ticket = passenger.reservation.ticket
    if ticket is None:
        ticket = await _find_ticket_by_number(
            db,
            analysis.normalized_ticket_number,
            with_booking=True,
        )
    if ticket is None:
        warnings.append("No matching ticket was found in our records.")
        return TicketImageScanResponse(
            decision="invalid_ticket",
            warnings=warnings,
            normalized_ticket_number=analysis.normalized_ticket_number,
            extracted_fields=analysis.extracted_fields,
            field_confidence=analysis.field_confidence,
            raw_text=analysis.raw_text,
        )

    db_match = _to_db_match_from_passenger(passenger) if passenger else _to_db_match(ticket)
    if ticket.status != TicketStatus.VALID.value:
        warnings.append("Ticket is not currently valid for check-in.")
        return TicketImageScanResponse(
            decision="invalid_ticket",
            warnings=warnings,
            normalized_ticket_number=analysis.normalized_ticket_number,
            extracted_fields=analysis.extracted_fields,
            field_confidence=analysis.field_confidence,
            raw_text=analysis.raw_text,
            db_match=db_match,
        )

    departure_at = (
        passenger.reservation.flight.departure_at
        if passenger
        else ticket.booking.flight.departure_at
    )
    if departure_at.tzinfo is None:
        warnings.append("Departure time timezone is missing; cannot evaluate ticket expiry safely.")
        return TicketImageScanResponse(
            decision="invalid_ticket",
            warnings=warnings,
            normalized_ticket_number=analysis.normalized_ticket_number,
            extracted_fields=analysis.extracted_fields,
            field_confidence=analysis.field_confidence,
            raw_text=analysis.raw_text,
            db_match=db_match,
        )
    expiry_deadline = departure_at + timedelta(minutes=settings.TICKET_EXPIRY_GRACE_MINUTES)
    if datetime.now(UTC) > expiry_deadline:
        warnings.append("Ticket is expired and can no longer be used.")
        return TicketImageScanResponse(
            decision="expired_ticket",
            warnings=warnings,
            normalized_ticket_number=analysis.normalized_ticket_number,
            extracted_fields=analysis.extracted_fields,
            field_confidence=analysis.field_confidence,
            raw_text=analysis.raw_text,
            db_match=db_match,
        )

    return TicketImageScanResponse(
        decision="valid_ticket",
        warnings=warnings,
        normalized_ticket_number=analysis.normalized_ticket_number,
        extracted_fields=analysis.extracted_fields,
        field_confidence=analysis.field_confidence,
        raw_text=analysis.raw_text,
        db_match=db_match,
    )
