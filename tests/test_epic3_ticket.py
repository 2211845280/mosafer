"""Epic 3 ticket helpers tests."""

import json
from datetime import UTC, datetime

from app.core.ticket_pdf import build_ticket_pdf_bytes
from app.core.ticket_qr import qr_content_for_ticket


def test_qr_content_is_uppercased_ticket_number():
    payload = json.loads(qr_content_for_ticket("ab12cd"))
    assert payload["ticket_number"] == "AB12CD"


def test_ticket_pdf_starts_with_pdf_header():
    raw = build_ticket_pdf_bytes(
        ticket_number="077-1234567890",
        booking_id=1,
        seat="12A",
        carrier_code="MS",
        carrier_name="EgyptAir",
        flight_number="MS117",
        origin_iata="MJI",
        destination_iata="CAI",
        departure_at=datetime.now(UTC).isoformat(),
        arrival_at=datetime.now(UTC).isoformat(),
        qr_image_relative=None,
        pnr="ABC123",
        passenger_name="DOE/JOHN",
    )
    assert raw[:5] == b"%PDF-"

