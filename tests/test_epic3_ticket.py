"""Epic 3 ticket helpers tests."""

from datetime import datetime, timezone

from app.core.ticket_pdf import build_ticket_pdf_bytes
from app.core.ticket_qr import qr_content_for_ticket


def test_qr_content_is_uppercased_ticket_number():
    assert qr_content_for_ticket("ab12cd") == "AB12CD"


def test_ticket_pdf_starts_with_pdf_header():
    raw = build_ticket_pdf_bytes(
        ticket_number="TN1",
        booking_id=1,
        seat="12A",
        carrier_code="MS",
        flight_number="101",
        origin_iata="CAI",
        destination_iata="DXB",
        departure_at=datetime.now(timezone.utc).isoformat(),
        arrival_at=datetime.now(timezone.utc).isoformat(),
        qr_image_relative=None,
    )
    assert raw[:5] == b"%PDF-"

