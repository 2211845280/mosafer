"""Epic 2: airports, flights, reservations, tickets tables + RBAC permissions.

Revision ID: 8f3e9a1b2c4d
Revises: 60eece5c6296
Create Date: 2026-03-29

"""

from collections.abc import Sequence
from datetime import datetime

import sqlalchemy as sa
from alembic import op

revision: str = "8f3e9a1b2c4d"
down_revision: str | None = "60eece5c6296"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "airports",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("iata_code", sa.String(length=3), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("city", sa.String(length=128), nullable=False),
        sa.Column("country", sa.String(length=128), nullable=False),
        sa.Column("timezone", sa.String(length=64), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_airports_id"), "airports", ["id"], unique=False)
    op.create_index(op.f("ix_airports_iata_code"), "airports", ["iata_code"], unique=True)

    op.create_table(
        "flights",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("flight_number", sa.String(length=32), nullable=False),
        sa.Column("origin_airport_id", sa.Integer(), nullable=False),
        sa.Column("destination_airport_id", sa.Integer(), nullable=False),
        sa.Column("departure_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("arrival_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("base_price", sa.Numeric(12, 2), nullable=False),
        sa.Column("total_seats", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["destination_airport_id"], ["airports.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["origin_airport_id"], ["airports.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_flights_departure_at"), "flights", ["departure_at"], unique=False)
    op.create_index(op.f("ix_flights_destination_airport_id"), "flights", ["destination_airport_id"], unique=False)
    op.create_index(op.f("ix_flights_flight_number"), "flights", ["flight_number"], unique=False)
    op.create_index(op.f("ix_flights_id"), "flights", ["id"], unique=False)
    op.create_index(op.f("ix_flights_origin_airport_id"), "flights", ["origin_airport_id"], unique=False)

    op.create_table(
        "reservations",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("flight_id", sa.Integer(), nullable=False),
        sa.Column("seat", sa.String(length=8), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["flight_id"], ["flights.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("flight_id", "seat", name="uq_reservations_flight_seat"),
    )
    op.create_index(op.f("ix_reservations_flight_id"), "reservations", ["flight_id"], unique=False)
    op.create_index(op.f("ix_reservations_id"), "reservations", ["id"], unique=False)
    op.create_index(op.f("ix_reservations_user_id"), "reservations", ["user_id"], unique=False)

    op.create_table(
        "tickets",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("reservation_id", sa.Integer(), nullable=False),
        sa.Column("ticket_number", sa.String(length=32), nullable=False),
        sa.Column("qr_payload", sa.String(length=512), nullable=False),
        sa.Column("qr_image_path", sa.String(length=500), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["reservation_id"], ["reservations.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_tickets_id"), "tickets", ["id"], unique=False)
    op.create_index(op.f("ix_tickets_reservation_id"), "tickets", ["reservation_id"], unique=True)
    op.create_index(op.f("ix_tickets_ticket_number"), "tickets", ["ticket_number"], unique=True)

    now = datetime.utcnow()
    conn = op.get_bind()

    perms = [
        ("airports.manage", "Manage airports"),
        ("flights.manage", "Manage flights"),
        ("flights.read", "Search and view flights"),
        ("bookings.create", "Create reservations"),
        ("bookings.cancel", "Cancel own reservations"),
        ("tickets.view", "View own tickets"),
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
            JOIN permissions p ON p.name IN (
                'flights.read',
                'bookings.create',
                'bookings.cancel',
                'tickets.view'
            )
            WHERE r.name = 'user'
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
            JOIN permissions p ON p.name IN (
                'airports.manage',
                'flights.manage',
                'flights.read',
                'bookings.create',
                'bookings.cancel',
                'tickets.view'
            )
            WHERE r.name = 'admin'
            AND NOT EXISTS (
                SELECT 1 FROM role_permissions rp
                WHERE rp.role_id = r.id AND rp.permission_id = p.id
            )
            """,
        ),
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_tickets_ticket_number"), table_name="tickets")
    op.drop_index(op.f("ix_tickets_reservation_id"), table_name="tickets")
    op.drop_index(op.f("ix_tickets_id"), table_name="tickets")
    op.drop_table("tickets")
    op.drop_index(op.f("ix_reservations_user_id"), table_name="reservations")
    op.drop_index(op.f("ix_reservations_id"), table_name="reservations")
    op.drop_index(op.f("ix_reservations_flight_id"), table_name="reservations")
    op.drop_table("reservations")
    op.drop_index(op.f("ix_flights_origin_airport_id"), table_name="flights")
    op.drop_index(op.f("ix_flights_id"), table_name="flights")
    op.drop_index(op.f("ix_flights_flight_number"), table_name="flights")
    op.drop_index(op.f("ix_flights_destination_airport_id"), table_name="flights")
    op.drop_index(op.f("ix_flights_departure_at"), table_name="flights")
    op.drop_table("flights")
    op.drop_index(op.f("ix_airports_iata_code"), table_name="airports")
    op.drop_index(op.f("ix_airports_id"), table_name="airports")
    op.drop_table("airports")
