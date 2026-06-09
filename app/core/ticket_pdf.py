"""Generate a realistic e-ticket PDF."""

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


def _fmt_dt(iso: str) -> str:
    try:
        from datetime import datetime

        dt = datetime.fromisoformat(iso.replace("Z", "+00:00"))
        return dt.strftime("%d %b %Y  %H:%M")
    except (ValueError, TypeError):
        return iso


def build_ticket_pdf_bytes(
    *,
    ticket_number: str,
    booking_id: int,
    seat: str,
    carrier_code: str,
    carrier_name: str,
    flight_number: str,
    origin_iata: str,
    destination_iata: str,
    departure_at: str,
    arrival_at: str,
    qr_image_relative: str | None,
    pnr: str | None = None,
    passenger_name: str | None = None,
    cabin_class: str | None = None,
    baggage_allowance: str | None = None,
    departure_terminal: str | None = None,
) -> bytes:
    """Return PDF bytes styled like an airline e-ticket receipt."""
    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)

    # Header bar
    pdf.set_fill_color(6, 19, 38)
    pdf.rect(0, 0, 210, 28, style="F")
    pdf.set_text_color(217, 229, 255)
    pdf.set_font("Helvetica", "B", 16)
    pdf.set_xy(15, 8)
    pdf.cell(0, 8, text=carrier_name.upper(), new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", size=9)
    pdf.set_xy(15, 18)
    pdf.cell(0, 5, text=f"ELECTRONIC TICKET RECEIPT  |  {carrier_code} {flight_number}")

    pdf.set_text_color(30, 30, 30)
    pdf.set_xy(15, 36)

    def row(label: str, value: str, bold: bool = False) -> None:
        pdf.set_font("Helvetica", size=9)
        pdf.set_text_color(112, 129, 157)
        pdf.cell(55, 6, text=label)
        pdf.set_font("Helvetica", "B" if bold else "", size=10)
        pdf.set_text_color(30, 30, 30)
        pdf.cell(0, 6, text=value, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    pdf.set_font("Helvetica", "B", 12)
    pdf.set_text_color(30, 30, 30)
    pdf.cell(0, 8, text="Passenger", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(2)
    row("Name", passenger_name or "— (pending passenger details)", bold=True)
    row("Seat", seat.upper(), bold=True)
    if cabin_class:
        row("Class", cabin_class)

    pdf.ln(4)
    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 8, text="Booking reference", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(2)
    row("PNR / Record locator", pnr or "—", bold=True)
    row("E-Ticket number", ticket_number, bold=True)
    row("Booking ID", f"#{booking_id}")

    pdf.ln(4)
    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 8, text="Flight", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(2)
    row("Flight", f"{carrier_code} {flight_number}  ({carrier_name})", bold=True)
    row("From", origin_iata, bold=True)
    row("To", destination_iata, bold=True)
    row("Departure", _fmt_dt(departure_at), bold=True)
    row("Arrival", _fmt_dt(arrival_at))
    if departure_terminal:
        row("Terminal", departure_terminal)
    if baggage_allowance:
        row("Baggage", baggage_allowance)

    img = _resolve_qr_image(qr_image_relative)
    if img is not None:
        pdf.ln(6)
        pdf.set_font("Helvetica", size=8)
        pdf.set_text_color(112, 129, 157)
        pdf.cell(0, 5, text="Scan at airport check-in", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        pdf.image(str(img), x=15, y=pdf.get_y() + 2, w=45)

    pdf.set_y(-25)
    pdf.set_font("Helvetica", "I", size=8)
    pdf.set_text_color(112, 129, 157)
    pdf.cell(
        0,
        5,
        text="This is a demo e-ticket issued by Mosafer. Present passport matching passenger name at check-in.",
        align="C",
        new_x=XPos.LMARGIN,
        new_y=YPos.NEXT,
    )

    buf = BytesIO()
    pdf.output(buf)
    return buf.getvalue()
