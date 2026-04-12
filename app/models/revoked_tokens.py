"""SQLAlchemy ORM model for revoked JWT tokens."""

<<<<<<< HEAD
from datetime import UTC, datetime
=======
from datetime import datetime
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class RevokedToken(Base):
    """Stores revoked token metadata for blacklist checks."""

    __tablename__ = "revoked_tokens"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    jti: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    logout_hash: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    execute_hash: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    revoked_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
<<<<<<< HEAD
        default=lambda: datetime.now(UTC),
=======
        default=datetime.utcnow,
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
        nullable=False,
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
