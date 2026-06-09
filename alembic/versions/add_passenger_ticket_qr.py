"""Add per-passenger ticket number and QR fields."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "add_passenger_ticket_qr"
down_revision: str | None = "add_reservation_seats"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "booking_passengers",
        sa.Column("passenger_ticket_number", sa.String(length=40), nullable=True),
    )
    op.add_column(
        "booking_passengers",
        sa.Column("qr_code", sa.String(length=512), nullable=True),
    )
    op.add_column(
        "booking_passengers",
        sa.Column("qr_image_path", sa.String(length=500), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("booking_passengers", "qr_image_path")
    op.drop_column("booking_passengers", "qr_code")
    op.drop_column("booking_passengers", "passenger_ticket_number")
