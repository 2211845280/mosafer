"""Generate ticket QR code images."""

import json
from pathlib import Path

import qrcode
from qrcode.constants import ERROR_CORRECT_M

from app.core.config import settings


def build_qr_payload(ticket_number: str, reservation_id: int) -> str:
    """Build compact JSON payload for QR scanning."""
    return json.dumps({"tn": ticket_number, "rid": reservation_id}, separators=(",", ":"))


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
