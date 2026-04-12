"""SQLAlchemy ORM model for booked/selected flights."""

from datetime import UTC, datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class Flight(Base):
    """Booked/selected flight persisted from provider offers."""

    __tablename__ = "flights"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    provider_flight_id: Mapped[str] = mapped_column(
        String(128),
        unique=True,
        nullable=False,
        index=True,
    )
    origin_iata: Mapped[str] = mapped_column(String(3), nullable=False, index=True)
    destination_iata: Mapped[str] = mapped_column(String(3), nullable=False, index=True)
    carrier_code: Mapped[str] = mapped_column(String(3), nullable=False, index=True)
    flight_number: Mapped[str] = mapped_column(String(32), nullable=False, index=True)
    origin_airport_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("airports.id", ondelete="RESTRICT"),
        nullable=True,
        index=True,
    )
    destination_airport_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("airports.id", ondelete="RESTRICT"),
        nullable=True,
        index=True,
    )
    departure_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, index=True
    )
    arrival_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    base_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    currency: Mapped[str | None] = mapped_column(String(3), nullable=True)
    total_seats: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    origin_airport = relationship(
        "Airport",
        foreign_keys=[origin_airport_id],
        back_populates="departing_flights",
    )
    destination_airport = relationship(
        "Airport",
        foreign_keys=[destination_airport_id],
        back_populates="arriving_flights",
    )
    reservations = relationship("Reservation", back_populates="flight")
