"""SQLAlchemy ORM model for tickets."""

from datetime import datetime
from enum import StrEnum

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class TicketStatus(StrEnum):
    """Ticket lifecycle."""

    ISSUED = "issued"
    USED = "used"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"


class Ticket(Base):
    """Ticket issued for a reservation with QR reference."""

    __tablename__ = "tickets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    reservation_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("reservations.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    ticket_number: Mapped[str] = mapped_column(String(32), unique=True, nullable=False, index=True)
    qr_payload: Mapped[str] = mapped_column(String(512), nullable=False)
    qr_image_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default=TicketStatus.ISSUED.value)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        nullable=False,
    )

    reservation = relationship("Reservation", back_populates="ticket")
