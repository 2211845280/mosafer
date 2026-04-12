"""SQLAlchemy ORM model for airports."""

<<<<<<< HEAD
from datetime import UTC, datetime

from sqlalchemy import DateTime, Integer, JSON, Numeric, String
=======
from datetime import datetime

from sqlalchemy import DateTime, Integer, String
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
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
<<<<<<< HEAD
    latitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    longitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    terminal_info: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    amenities: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    map_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
=======
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
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
