"""Bootstrap fresh databases and run Alembic upgrades on existing ones."""

from __future__ import annotations

import asyncio
import sys

from alembic import command
from alembic.config import Config
from sqlalchemy import inspect, text

from app.db.database import AsyncSessionLocal, Base, engine
from app.db.rbac_seed import seed_rbac
from app.models import (  # noqa: F401
    Admin,
    Airport,
    BookingPassenger,
    DeviceToken,
    Flight,
    Notification,
    Passenger,
    Payment,
    Permission,
    RefreshToken,
    Reservation,
    ReservationSeat,
    RevokedToken,
    Role,
    RolePermission,
    Ticket,
    TicketImage,
    TripFeedback,
    TripTodo,
    User,
    UserPreference,
)

ALEMBIC_HEAD = "add_reservation_hidden_at"


async def _users_table_exists() -> bool:
    async with engine.connect() as conn:

        def check(connection) -> bool:
            return inspect(connection).has_table("users")

        return await conn.run_sync(check)


async def _alembic_revision() -> str | None:
    async with engine.connect() as conn:

        def check(connection) -> str | None:
            if not inspect(connection).has_table("alembic_version"):
                return None
            row = connection.execute(
                text("SELECT version_num FROM alembic_version LIMIT 1"),
            ).first()
            return row[0] if row else None

        return await conn.run_sync(check)


async def _roles_seeded() -> bool:
    async with engine.connect() as conn:

        def check(connection) -> bool:
            if not inspect(connection).has_table("roles"):
                return False
            row = connection.execute(text("SELECT COUNT(*) FROM roles")).first()
            return row is not None and row[0] > 0

        return await conn.run_sync(check)


async def _bootstrap_fresh_schema() -> None:
    print("Fresh database detected; creating schema from SQLAlchemy models...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def _seed_rbac_if_needed() -> None:
    if await _roles_seeded():
        return
    print("Seeding RBAC roles and permissions...")
    async with AsyncSessionLocal() as session:
        await seed_rbac(session)
        await session.commit()


async def prepare_database() -> str:
    """Return the Alembic action needed after async DB work completes."""
    if not await _users_table_exists():
        await _bootstrap_fresh_schema()
        await _seed_rbac_if_needed()
        return "stamp"

    revision = await _alembic_revision()
    if revision is None:
        await _seed_rbac_if_needed()
        return "stamp"

    if revision != ALEMBIC_HEAD:
        return "upgrade"

    await _seed_rbac_if_needed()
    return "none"


def _stamp_head() -> None:
    print(f"Stamping Alembic at head ({ALEMBIC_HEAD})...")
    cfg = Config("alembic.ini")
    command.stamp(cfg, ALEMBIC_HEAD)
    print("Database bootstrap complete.")


def _upgrade_head() -> None:
    print("Existing database detected; running Alembic upgrades...")
    cfg = Config("alembic.ini")
    command.upgrade(cfg, "head")
    print("Alembic upgrades complete.")


def main() -> None:
    try:
        action = asyncio.run(prepare_database())
        if action == "stamp":
            _stamp_head()
        elif action == "upgrade":
            _upgrade_head()
            asyncio.run(_seed_rbac_if_needed())
        else:
            print("Database schema is up to date.")
    except Exception as exc:
        print(f"Migration failed: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    finally:
        asyncio.run(engine.dispose())


if __name__ == "__main__":
    main()
