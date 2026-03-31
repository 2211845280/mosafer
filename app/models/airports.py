"""SQLAlchemy ORM model for airports."""

from datetime import datetime

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class Airport(Base):
    """Airport model (IATA code)."""

    __tablename__ = "airports"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    iata_code: Mapped[str] = mapped_column(String(3), unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    city: Mapped[str] = mapped_column(String(128), nullable=False)
    country: Mapped[str] = mapped_column(String(128), nullable=False)
    timezone: Mapped[str | None] = mapped_column(String(64), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        nullable=False,
    )

    departing_flights = relationship(
        "Flight",
        foreign_keys="Flight.origin_airport_id",
        back_populates="origin_airport",
    )
    arriving_flights = relationship(
        "Flight",
        foreign_keys="Flight.destination_airport_id",
        back_populates="destination_airport",
    )
