"""Epic 2 Amadeus alignment.

Revision ID: 9c1f6e2a4b11
Revises: f256384d0ae8
Create Date: 2026-03-31
"""

from collections.abc import Sequence
from datetime import datetime

import sqlalchemy as sa
from alembic import op

revision: str = "9c1f6e2a4b11"
down_revision: str | None = "f256384d0ae8"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("flights", sa.Column("amadeus_flight_id", sa.String(length=128), nullable=True))
    op.add_column("flights", sa.Column("origin_iata", sa.String(length=3), nullable=True))
    op.add_column("flights", sa.Column("destination_iata", sa.String(length=3), nullable=True))
    op.add_column("flights", sa.Column("carrier_code", sa.String(length=3), nullable=True))
    op.add_column("flights", sa.Column("currency", sa.String(length=3), nullable=True))

    op.alter_column("flights", "origin_airport_id", existing_type=sa.Integer(), nullable=True)
    op.alter_column("flights", "destination_airport_id", existing_type=sa.Integer(), nullable=True)
    op.alter_column("flights", "base_price", existing_type=sa.Numeric(precision=12, scale=2), nullable=True)
    op.alter_column("flights", "total_seats", existing_type=sa.Integer(), nullable=True)

    conn = op.get_bind()
    conn.execute(
        sa.text(
            """
            UPDATE flights f
            SET origin_iata = a.iata_code
            FROM airports a
            WHERE a.id = f.origin_airport_id
            """,
        ),
    )
    conn.execute(
        sa.text(
            """
            UPDATE flights f
            SET destination_iata = a.iata_code
            FROM airports a
            WHERE a.id = f.destination_airport_id
            """,
        ),
    )
    conn.execute(sa.text("UPDATE flights SET carrier_code = 'XX'"))
    conn.execute(sa.text("UPDATE flights SET amadeus_flight_id = 'LEGACY-' || id::text"))
    conn.execute(sa.text("UPDATE flights SET origin_iata='UNK' WHERE origin_iata IS NULL"))
    conn.execute(sa.text("UPDATE flights SET destination_iata='UNK' WHERE destination_iata IS NULL"))
    conn.execute(sa.text("UPDATE flights SET carrier_code='XX' WHERE carrier_code IS NULL"))
    conn.execute(
        sa.text(
            "UPDATE flights SET amadeus_flight_id='LEGACY-' || id::text WHERE amadeus_flight_id IS NULL",
        ),
    )

    op.alter_column("flights", "amadeus_flight_id", existing_type=sa.String(length=128), nullable=False)
    op.alter_column("flights", "origin_iata", existing_type=sa.String(length=3), nullable=False)
    op.alter_column("flights", "destination_iata", existing_type=sa.String(length=3), nullable=False)
    op.alter_column("flights", "carrier_code", existing_type=sa.String(length=3), nullable=False)
    op.create_index(op.f("ix_flights_amadeus_flight_id"), "flights", ["amadeus_flight_id"], unique=True)
    op.create_index(op.f("ix_flights_origin_iata"), "flights", ["origin_iata"], unique=False)
    op.create_index(op.f("ix_flights_destination_iata"), "flights", ["destination_iata"], unique=False)
    op.create_index(op.f("ix_flights_carrier_code"), "flights", ["carrier_code"], unique=False)

    op.add_column("reservations", sa.Column("total_price", sa.Float(), nullable=True))
    op.add_column("reservations", sa.Column("currency", sa.String(length=3), nullable=True))

    conn.execute(
        sa.text(
            """
            UPDATE reservations
            SET status = CASE
                WHEN status = 'confirmed' THEN 'booked'
                WHEN status = 'cancelled' THEN 'canceled'
                ELSE status
            END
            """,
        ),
    )

    now = datetime.utcnow()
    perms = [
        ("tickets.validate", "Validate tickets"),
        ("tickets.history.view", "View ticket history"),
        ("tickets.report.view", "View ticket reports"),
    ]
    for name, desc in perms:
        conn.execute(
            sa.text(
                """
                INSERT INTO permissions (name, description, created_at)
                VALUES (:name, :description, :created_at)
                ON CONFLICT (name) DO NOTHING
                """,
            ),
            {"name": name, "description": desc, "created_at": now},
        )

    op.execute(
        sa.text(
            """
            INSERT INTO role_permissions (role_id, permission_id, created_at)
            SELECT r.id, p.id, now()
            FROM roles r
            JOIN permissions p ON p.name = 'tickets.validate'
            WHERE r.name = 'admin'
            AND NOT EXISTS (
                SELECT 1 FROM role_permissions rp
                WHERE rp.role_id = r.id AND rp.permission_id = p.id
            )
            """,
        ),
    )
    op.execute(
        sa.text(
            """
            INSERT INTO role_permissions (role_id, permission_id, created_at)
            SELECT r.id, p.id, now()
            FROM roles r
            JOIN permissions p ON p.name IN ('tickets.history.view', 'tickets.report.view')
            WHERE r.name = 'admin'
            AND NOT EXISTS (
                SELECT 1 FROM role_permissions rp
                WHERE rp.role_id = r.id AND rp.permission_id = p.id
            )
            """,
        ),
    )


def downgrade() -> None:
    op.drop_column("reservations", "currency")
    op.drop_column("reservations", "total_price")

    op.drop_index(op.f("ix_flights_carrier_code"), table_name="flights")
    op.drop_index(op.f("ix_flights_destination_iata"), table_name="flights")
    op.drop_index(op.f("ix_flights_origin_iata"), table_name="flights")
    op.drop_index(op.f("ix_flights_amadeus_flight_id"), table_name="flights")

    op.alter_column("flights", "total_seats", existing_type=sa.Integer(), nullable=False)
    op.alter_column("flights", "base_price", existing_type=sa.Numeric(precision=12, scale=2), nullable=False)
    op.alter_column("flights", "destination_airport_id", existing_type=sa.Integer(), nullable=False)
    op.alter_column("flights", "origin_airport_id", existing_type=sa.Integer(), nullable=False)

    op.drop_column("flights", "currency")
    op.drop_column("flights", "carrier_code")
    op.drop_column("flights", "destination_iata")
    op.drop_column("flights", "origin_iata")
    op.drop_column("flights", "amadeus_flight_id")
