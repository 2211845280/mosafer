"""Generate a simple PDF for a ticket (QR + booking text)."""

from io import BytesIO
from pathlib import Path

from fpdf import FPDF
from fpdf.enums import XPos, YPos

from app.core.config import settings


def _resolve_qr_image(qr_image_relative: str | None) -> Path | None:
    if not qr_image_relative:
        return None
    p = Path(qr_image_relative)
    if p.is_file():
        return p
    alt = Path(settings.TICKET_QR_DIR) / p.name
    if alt.is_file():
        return alt
    cwd = Path.cwd() / qr_image_relative
    if cwd.is_file():
        return cwd
    return None


def build_ticket_pdf_bytes(
    *,
    ticket_number: str,
    booking_id: int,
    seat: str,
    carrier_code: str,
    flight_number: str,
    origin_iata: str,
    destination_iata: str,
    departure_at: str,
    arrival_at: str,
    qr_image_relative: str | None,
) -> bytes:
    """Return PDF bytes; embeds QR PNG when file exists."""
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Helvetica", size=14)
<<<<<<< HEAD
    pdf.cell(0, 10, text="Mosafer ticket", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
=======
    pdf.cell(0, 10, text="Musafir ticket", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
    pdf.set_font("Helvetica", size=11)
    pdf.cell(0, 8, text=f"Ticket number: {ticket_number}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.cell(0, 8, text=f"Booking ID: {booking_id}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.cell(0, 8, text=f"Seat: {seat}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.cell(0, 8, text=f"Flight: {carrier_code} {flight_number}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.cell(0, 8, text=f"Route: {origin_iata} - {destination_iata}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.cell(0, 8, text=f"Departure: {departure_at}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.cell(0, 8, text=f"Arrival: {arrival_at}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    img = _resolve_qr_image(qr_image_relative)
    if img is not None:
        pdf.image(str(img), x=15, y=70, w=55)

    buf = BytesIO()
    pdf.output(buf)
    return buf.getvalue()
