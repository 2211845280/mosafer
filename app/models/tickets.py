"""SQLAlchemy ORM model for tickets."""

from datetime import UTC, datetime
from enum import StrEnum

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class TicketStatus(StrEnum):
    """Ticket lifecycle (local-only, Epic 3)."""

    VALID = "valid"
    USED = "used"
    CANCELED = "canceled"


class Ticket(Base):
    """Ticket issued for a booking with QR reference."""

    __tablename__ = "tickets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    booking_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("reservations.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    ticket_number: Mapped[str] = mapped_column(String(32), unique=True, nullable=False, index=True)
    qr_code: Mapped[str] = mapped_column(String(512), nullable=False)
    qr_image_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    status: Mapped[str] = mapped_column(
        String(32), nullable=False, default=TicketStatus.VALID.value
    )
    issued_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    booking = relationship("Reservation", back_populates="ticket")
    images = relationship("TicketImage", back_populates="ticket", cascade="all, delete-orphan")


class TicketImage(Base):
    """User-uploaded files linked to a ticket."""

    __tablename__ = "ticket_images"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    ticket_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("tickets.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    file_path: Mapped[str] = mapped_column(String(500), nullable=False)
    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    ticket = relationship("Ticket", back_populates="images")
