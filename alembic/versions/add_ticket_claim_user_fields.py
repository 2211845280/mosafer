"""Add ticket claim ownership fields."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "add_ticket_claim_user_fields"
down_revision: str | None = "add_trip_todo_bilingual_fields"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "tickets",
        sa.Column("ordered_by_user_id", sa.Integer(), nullable=True),
    )
    op.add_column(
        "tickets",
        sa.Column("assigned_to_user_id", sa.Integer(), nullable=True),
    )
    op.create_index("ix_tickets_ordered_by_user_id", "tickets", ["ordered_by_user_id"])
    op.create_index("ix_tickets_assigned_to_user_id", "tickets", ["assigned_to_user_id"])

    op.add_column(
        "booking_passengers",
        sa.Column("ordered_by_user_id", sa.Integer(), nullable=True),
    )
    op.add_column(
        "booking_passengers",
        sa.Column("assigned_to_user_id", sa.Integer(), nullable=True),
    )
    op.create_index(
        "ix_booking_passengers_ordered_by_user_id",
        "booking_passengers",
        ["ordered_by_user_id"],
    )
    op.create_index(
        "ix_booking_passengers_assigned_to_user_id",
        "booking_passengers",
        ["assigned_to_user_id"],
    )

    op.execute(
        sa.text(
            """
            UPDATE tickets
            SET ordered_by_user_id = (
                SELECT reservations.user_id
                FROM reservations
                WHERE reservations.id = tickets.booking_id
            )
            WHERE ordered_by_user_id IS NULL
            """,
        ),
    )
    op.execute(
        sa.text(
            """
            UPDATE booking_passengers
            SET ordered_by_user_id = (
                SELECT reservations.user_id
                FROM reservations
                WHERE reservations.id = booking_passengers.reservation_id
            )
            WHERE ordered_by_user_id IS NULL
            """,
        ),
    )


def downgrade() -> None:
    op.drop_index("ix_booking_passengers_assigned_to_user_id", table_name="booking_passengers")
    op.drop_index("ix_booking_passengers_ordered_by_user_id", table_name="booking_passengers")
    op.drop_column("booking_passengers", "assigned_to_user_id")
    op.drop_column("booking_passengers", "ordered_by_user_id")

    op.drop_index("ix_tickets_assigned_to_user_id", table_name="tickets")
    op.drop_index("ix_tickets_ordered_by_user_id", table_name="tickets")
    op.drop_column("tickets", "assigned_to_user_id")
    op.drop_column("tickets", "ordered_by_user_id")
