"""Integration tests for notifications API."""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notifications import Notification
from app.models.users import User


@pytest.mark.asyncio
async def test_delete_notification_owned_by_user(
    prepare_schema,
    client: AsyncClient,
    db_session: AsyncSession,
    authed_user: tuple[User, dict[str, str]],
) -> None:
    user, headers = authed_user
    note = Notification(
        user_id=user.id,
        type="trip_todo_3d",
        title="Trip tasks reminder",
        body="Please complete tasks",
        read=False,
    )
    db_session.add(note)
    await db_session.commit()
    await db_session.refresh(note)

    response = await client.delete(f"/notifications/{note.id}", headers=headers)
    assert response.status_code == 204

    list_response = await client.get("/notifications", headers=headers)
    assert list_response.status_code == 200
    items = list_response.json()["items"]
    assert all(item["id"] != note.id for item in items)


@pytest.mark.asyncio
async def test_delete_notification_not_owned_returns_404(
    prepare_schema,
    client: AsyncClient,
    db_session: AsyncSession,
    authed_user: tuple[User, dict[str, str]],
) -> None:
    user, headers = authed_user
    from app.models.roles import Role

    other_role = Role(name="other-tester", description="other")
    db_session.add(other_role)
    await db_session.flush()
    other_user = User(
        email="other-notif@example.com",
        password_hash="hashed",
        role_id=other_role.id,
        is_active=True,
        is_email_verified=True,
    )
    db_session.add(other_user)
    await db_session.flush()

    note = Notification(
        user_id=other_user.id,
        type="flight_departure_6h",
        title="Reminder",
        body="Body",
        read=False,
    )
    db_session.add(note)
    await db_session.commit()
    await db_session.refresh(note)

    response = await client.delete(f"/notifications/{note.id}", headers=headers)
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_mark_notifications_read(
    prepare_schema,
    client: AsyncClient,
    db_session: AsyncSession,
    authed_user: tuple[User, dict[str, str]],
) -> None:
    user, headers = authed_user
    note = Notification(
        user_id=user.id,
        type="home_departure_2h",
        title="Reminder",
        body="Leave soon",
        read=False,
    )
    db_session.add(note)
    await db_session.commit()
    await db_session.refresh(note)

    response = await client.post(
        "/notifications/read",
        headers=headers,
        json={"ids": [note.id]},
    )
    assert response.status_code == 200

    list_response = await client.get("/notifications", headers=headers)
    item = list_response.json()["items"][0]
    assert item["read"] is True
