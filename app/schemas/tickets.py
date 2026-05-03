"""Pydantic schemas for tickets."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class FlightSummaryForTicket(BaseModel):
    """Minimal flight + seat info on a ticket."""

    carrier_code: str
    flight_number: str
    origin_iata: str
    destination_iata: str
    departure_at: datetime
    arrival_at: datetime
    seat: str


class TicketRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    booking_id: int
    ticket_number: str
    qr_code: str
    qr_image_path: str | None
    status: str
    issued_at: datetime


class TicketListItem(BaseModel):
    """Ticket row for list/history with flight summary."""

    id: int
    booking_id: int
    ticket_number: str
    status: str
    issued_at: datetime
    qr_image_path: str | None
    flight: FlightSummaryForTicket


class TicketValidationResponse(BaseModel):
    ticket_number: str
    status: str
    ok: bool = Field(description="True only when transitioned valid→used")
    code: str
    message: str


class TicketReportResponse(BaseModel):
    total_tickets: int
    valid_count: int
    used_count: int
    canceled_count: int


class QRScanRequest(BaseModel):
    qr_payload: str = Field(..., min_length=1, description="Raw string from QR code scan")


class QRScanResponse(BaseModel):
    ticket_number: str
    ticket_status: str
    reservation_id: int
    reservation_status: str
    flight: FlightSummaryForTicket
    issued_at: datetime


class TicketImageExtractedFields(BaseModel):
    """Structured fields extracted from a ticket image."""

    ticket_number: str | None = None
    passenger_name: str | None = None
    carrier_code: str | None = None
    flight_number: str | None = None
    origin_iata: str | None = None
    destination_iata: str | None = None
    departure_at: datetime | None = None
    arrival_at: datetime | None = None
    seat: str | None = None
    ticket_status_hint: str | None = None


class TicketImageAnalysisResult(BaseModel):
    """Raw LLM analysis response prior to DB validation."""

    looks_like_ticket: bool = False
    warnings: list[str] = Field(default_factory=list)
    normalized_ticket_number: str | None = None
    extracted_fields: TicketImageExtractedFields = Field(
        default_factory=TicketImageExtractedFields
    )
    field_confidence: dict[str, float] = Field(default_factory=dict)
    raw_text: str = ""


class TicketImageDBMatch(BaseModel):
    """Ticket and flight info loaded from DB when a match exists."""

    ticket_number: str
    ticket_status: str
    reservation_id: int
    reservation_status: str
    flight: FlightSummaryForTicket
    issued_at: datetime


class TicketImageScanResponse(BaseModel):
    """Decision response for image-based ticket scan."""

    decision: Literal["invalid_ticket", "expired_ticket", "valid_ticket"]
    warnings: list[str] = Field(default_factory=list)
    normalized_ticket_number: str | None = None
    extracted_fields: TicketImageExtractedFields = Field(
        default_factory=TicketImageExtractedFields
    )
    field_confidence: dict[str, float] = Field(default_factory=dict)
    raw_text: str = ""
    db_match: TicketImageDBMatch | None = None


def flight_summary_from_booking(booking) -> FlightSummaryForTicket:
    """Build summary from Reservation ORM with loaded flight."""
    f = booking.flight
    return FlightSummaryForTicket(
        carrier_code=f.carrier_code,
        flight_number=f.flight_number,
        origin_iata=f.origin_iata,
        destination_iata=f.destination_iata,
        departure_at=f.departure_at,
        arrival_at=f.arrival_at,
        seat=booking.seat,
    )


def ticket_list_item(ticket) -> TicketListItem:
    """Build TicketListItem; booking + flight must be loaded."""
    return TicketListItem(
        id=ticket.id,
        booking_id=ticket.booking_id,
        ticket_number=ticket.ticket_number,
        status=ticket.status,
        issued_at=ticket.issued_at,
        qr_image_path=ticket.qr_image_path,
        flight=flight_summary_from_booking(ticket.booking),
    )
