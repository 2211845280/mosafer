"""SQLAlchemy ORM model for flights."""

from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class Flight(Base):
    """Scheduled flight between two airports."""

    __tablename__ = "flights"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    flight_number: Mapped[str] = mapped_column(String(32), nullable=False, index=True)
    origin_airport_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("airports.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    destination_airport_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("airports.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    departure_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    arrival_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    base_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    total_seats: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
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
