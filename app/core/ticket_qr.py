"""Generate ticket QR code images."""

import json
from pathlib import Path

import qrcode
from qrcode.constants import ERROR_CORRECT_M

from app.core.config import settings


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
    pnr: str | None = None,
    passenger_name: str | None = None,
    carrier_name: str | None = None,
) -> str:
    """Encode ticket + flight context as JSON for QR scanning."""
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
    if carrier_name is not None:
        payload["carrier_name"] = carrier_name
    if flight_number is not None:
        payload["flight_number"] = flight_number
    if seat is not None:
        payload["seat"] = seat
    if pnr is not None:
        payload["pnr"] = pnr
    if passenger_name is not None:
        payload["passenger"] = passenger_name
    return json.dumps(payload, separators=(",", ":"))


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
