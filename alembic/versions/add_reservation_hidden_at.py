"""Add hidden_at column to reservations for user-dismissed trips."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "add_reservation_hidden_at"
down_revision: str | None = "add_passenger_ticket_qr"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "reservations",
        sa.Column("hidden_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_reservations_hidden_at", "reservations", ["hidden_at"])


def downgrade() -> None:
    op.drop_index("ix_reservations_hidden_at", table_name="reservations")
    op.drop_column("reservations", "hidden_at")
