"""Add checkout_sessions and defer reservation creation until payment."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "add_checkout_sessions"
down_revision: str | None = "add_reservation_hidden_at"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "checkout_sessions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("flight_id", sa.Integer(), nullable=False),
        sa.Column("seats", sa.JSON(), nullable=False),
        sa.Column("adults_count", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("cabin_class", sa.String(length=32), nullable=True),
        sa.Column("total_price", sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column("currency", sa.String(length=3), nullable=True),
        sa.Column("passengers_json", sa.JSON(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="open"),
        sa.Column("reservation_id", sa.Integer(), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["flight_id"], ["flights.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["reservation_id"], ["reservations.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_checkout_sessions_id"), "checkout_sessions", ["id"], unique=False)
    op.create_index(
        op.f("ix_checkout_sessions_user_id"),
        "checkout_sessions",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_checkout_sessions_flight_id"),
        "checkout_sessions",
        ["flight_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_checkout_sessions_reservation_id"),
        "checkout_sessions",
        ["reservation_id"],
        unique=False,
    )

    op.add_column("payments", sa.Column("checkout_session_id", sa.Integer(), nullable=True))
    op.create_foreign_key(
        "fk_payments_checkout_session_id",
        "payments",
        "checkout_sessions",
        ["checkout_session_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index(
        op.f("ix_payments_checkout_session_id"),
        "payments",
        ["checkout_session_id"],
        unique=False,
    )
    op.alter_column("payments", "reservation_id", existing_type=sa.Integer(), nullable=True)

    # Legacy unpaid bookings should not appear as pending reservations.
    op.execute(
        sa.text(
            """
            UPDATE tickets
            SET status = 'canceled'
            WHERE booking_id IN (
                SELECT id FROM reservations WHERE status = 'booked'
            )
            """,
        ),
    )
    op.execute(
        sa.text(
            """
            UPDATE reservations
            SET status = 'canceled'
            WHERE status = 'booked'
            """,
        ),
    )


def downgrade() -> None:
    op.alter_column("payments", "reservation_id", existing_type=sa.Integer(), nullable=False)
    op.drop_index(op.f("ix_payments_checkout_session_id"), table_name="payments")
    op.drop_constraint("fk_payments_checkout_session_id", "payments", type_="foreignkey")
    op.drop_column("payments", "checkout_session_id")
    op.drop_index(op.f("ix_checkout_sessions_reservation_id"), table_name="checkout_sessions")
    op.drop_index(op.f("ix_checkout_sessions_flight_id"), table_name="checkout_sessions")
    op.drop_index(op.f("ix_checkout_sessions_user_id"), table_name="checkout_sessions")
    op.drop_index(op.f("ix_checkout_sessions_id"), table_name="checkout_sessions")
    op.drop_table("checkout_sessions")
