"""Seats locked per reservation (supports multi-passenger bookings)."""

from sqlalchemy import ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class ReservationSeat(Base):
    """One seat on a flight belonging to a reservation."""

    __tablename__ = "reservation_seats"
    __table_args__ = (
        UniqueConstraint("flight_id", "seat", name="uq_reservation_seats_flight_seat"),
        UniqueConstraint("reservation_id", "sequence", name="uq_reservation_seats_res_seq"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    reservation_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("reservations.id", ondelete="CASCADE"),
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
    sequence: Mapped[int] = mapped_column(Integer, nullable=False, default=1)

    reservation = relationship("Reservation", back_populates="reservation_seats")
    flight = relationship("Flight")
