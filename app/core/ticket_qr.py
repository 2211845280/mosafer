"""Generate ticket QR code images."""

<<<<<<< HEAD
import json
=======
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
from pathlib import Path

import qrcode
from qrcode.constants import ERROR_CORRECT_M

from app.core.config import settings


<<<<<<< HEAD
def qr_content_for_ticket(
    ticket_number: str,
    *,
    flight_id: int | None = None,
    origin_iata: str | None = None,
    destination_iata: str | None = None,
    departure_at: str | None = None,
    carrier_code: str | None = None,
    flight_number: str | None = None,
    seat: str | None = None,
) -> str:
    """Encode ticket + flight context as a JSON string for QR scanning.

    When called with only *ticket_number* (legacy path) the payload degrades
    gracefully to ``{"ticket_number": "..."}``.
    """
    payload: dict = {"ticket_number": ticket_number.strip().upper()}
    if flight_id is not None:
        payload["flight_id"] = flight_id
    if origin_iata is not None:
        payload["origin"] = origin_iata
    if destination_iata is not None:
        payload["destination"] = destination_iata
    if departure_at is not None:
        payload["departure_at"] = departure_at
    if carrier_code is not None:
        payload["carrier"] = carrier_code
    if flight_number is not None:
        payload["flight_number"] = flight_number
    if seat is not None:
        payload["seat"] = seat
    return json.dumps(payload, separators=(",", ":"))
=======
def qr_content_for_ticket(ticket_number: str) -> str:
    """QR encodes ticket number only (Epic 3)."""
    return ticket_number.strip().upper()
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767


def write_qr_png(payload: str, filename: str) -> str:
    """Write QR PNG under TICKET_QR_DIR; return stored relative path."""
    base = Path(settings.TICKET_QR_DIR)
    base.mkdir(parents=True, exist_ok=True)
    path = base / filename
    qr = qrcode.QRCode(version=1, error_correction=ERROR_CORRECT_M, box_size=10, border=2)
    qr.add_data(payload)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    img.save(path)
    return path.as_posix()
