"""Passenger details collected after payment for a booking."""

from datetime import UTC, date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class BookingPassenger(Base):
    """Traveler on a reservation (passport + name as on travel document)."""

    __tablename__ = "booking_passengers"
    __table_args__ = (
        UniqueConstraint("reservation_id", "sequence", name="uq_booking_passengers_res_seq"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    reservation_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("reservations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    sequence: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    title: Mapped[str] = mapped_column(String(8), nullable=False)  # MR, MRS, MS, MSTR
    given_name: Mapped[str] = mapped_column(String(80), nullable=False)
    family_name: Mapped[str] = mapped_column(String(80), nullable=False)
    date_of_birth: Mapped[date] = mapped_column(Date, nullable=False)
    gender: Mapped[str] = mapped_column(String(1), nullable=False)  # M / F
    nationality: Mapped[str] = mapped_column(String(3), nullable=False)
    passport_number: Mapped[str] = mapped_column(String(32), nullable=False)
    passport_expiry: Mapped[date] = mapped_column(Date, nullable=False)
    passport_issuing_country: Mapped[str] = mapped_column(String(3), nullable=False)
    seat: Mapped[str | None] = mapped_column(String(8), nullable=True)
    passenger_ticket_number: Mapped[str | None] = mapped_column(String(40), nullable=True)
    ordered_by_user_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    assigned_to_user_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    qr_code: Mapped[str | None] = mapped_column(String(512), nullable=True)
    qr_image_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    reservation = relationship("Reservation", back_populates="passengers")
