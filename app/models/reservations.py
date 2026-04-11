"""SQLAlchemy ORM model for bookings."""

from datetime import UTC, datetime
from decimal import Decimal
from enum import StrEnum

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class ReservationStatus(StrEnum):
    """Booking lifecycle."""

    BOOKED = "booked"
    PAID = "paid"
    CANCELED = "canceled"


class Reservation(Base):
    """User booking for a selected flight with a seat."""

    __tablename__ = "reservations"
    __table_args__ = (UniqueConstraint("flight_id", "seat", name="uq_reservations_flight_seat"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    flight_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("flights.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    seat: Mapped[str] = mapped_column(String(8), nullable=False)
    status: Mapped[str] = mapped_column(
        String(32), nullable=False, default=ReservationStatus.BOOKED.value
    )
    total_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    currency: Mapped[str | None] = mapped_column(String(3), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    user = relationship("User", backref="reservations")
    flight = relationship("Flight", back_populates="reservations")
    ticket = relationship("Ticket", back_populates="booking", uselist=False)
