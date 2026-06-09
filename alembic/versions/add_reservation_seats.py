"""Add reservation_seats table and booking_passengers.seat."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "add_reservation_seats"
down_revision: str | None = "add_passenger_passport_details"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "reservation_seats",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("reservation_id", sa.Integer(), nullable=False),
        sa.Column("flight_id", sa.Integer(), nullable=False),
        sa.Column("seat", sa.String(length=8), nullable=False),
        sa.Column("sequence", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["flight_id"], ["flights.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["reservation_id"], ["reservations.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("flight_id", "seat", name="uq_reservation_seats_flight_seat"),
        sa.UniqueConstraint("reservation_id", "sequence", name="uq_reservation_seats_res_seq"),
    )
    op.create_index(
        op.f("ix_reservation_seats_id"),
        "reservation_seats",
        ["id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_reservation_seats_reservation_id"),
        "reservation_seats",
        ["reservation_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_reservation_seats_flight_id"),
        "reservation_seats",
        ["flight_id"],
        unique=False,
    )

    op.execute(
        sa.text(
            """
            INSERT INTO reservation_seats (reservation_id, flight_id, seat, sequence)
            SELECT id, flight_id, seat, 1
            FROM reservations
            WHERE seat IS NOT NULL AND seat != ''
            """,
        ),
    )

    op.add_column(
        "booking_passengers",
        sa.Column("seat", sa.String(length=8), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("booking_passengers", "seat")
    op.drop_index(op.f("ix_reservation_seats_flight_id"), table_name="reservation_seats")
    op.drop_index(op.f("ix_reservation_seats_reservation_id"), table_name="reservation_seats")
    op.drop_index(op.f("ix_reservation_seats_id"), table_name="reservation_seats")
    op.drop_table("reservation_seats")
