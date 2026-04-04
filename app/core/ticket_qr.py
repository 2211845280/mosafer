"""Generate ticket QR code images."""

from pathlib import Path

import qrcode
from qrcode.constants import ERROR_CORRECT_M

from app.core.config import settings


def qr_content_for_ticket(ticket_number: str) -> str:
    """QR encodes ticket number only (Epic 3)."""
    return ticket_number.strip().upper()


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
