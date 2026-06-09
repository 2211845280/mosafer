"""Integration tests for auth endpoints."""

from __future__ import annotations

import uuid

import pytest
from sqlalchemy import select

from app.core.security import hash_password
from app.models.passenger import Passenger
from app.models.roles import Role
from app.models.users import User


@pytest.mark.asyncio
async def test_register_success(prepare_schema, client):
    payload = {
        "name": "Test User",
        "email": f"new-{uuid.uuid4().hex[:8]}@example.com",
        "password": "Secret123!",
    }
    response = await client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["message"]
    assert data["email"] == payload["email"]
    assert isinstance(data["user_id"], int)


@pytest.mark.asyncio
async def test_login_rejects_unverified_email(prepare_schema, client, db_session):
    role = Role(name="traveler", description="traveler")
    db_session.add(role)
    await db_session.flush()

    email = f"unverified-{uuid.uuid4().hex[:8]}@example.com"
    user = User(
        email=email,
        password_hash=hash_password("Secret123!"),
        role_id=role.id,
        is_active=True,
        is_email_verified=False,
    )
    db_session.add(user)
    await db_session.flush()
    db_session.add(
        Passenger(
            user_id=user.id,
            full_name="Unverified User",
            phone="unknown",
            passport_image="placeholder://pending",
            account_status="active",
        ),
    )
    await db_session.commit()

    response = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "Secret123!"},
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Please verify your email before logging in"


@pytest.mark.asyncio
async def test_login_allows_verified_email(prepare_schema, client, db_session):
    role = Role(name="traveler2", description="traveler")
    db_session.add(role)
    await db_session.flush()

    email = f"verified-{uuid.uuid4().hex[:8]}@example.com"
    user = User(
        email=email,
        password_hash=hash_password("Secret123!"),
        role_id=role.id,
        is_active=True,
        is_email_verified=True,
    )
    db_session.add(user)
    await db_session.flush()
    db_session.add(
        Passenger(
            user_id=user.id,
            full_name="Verified User",
            phone="unknown",
            passport_image="placeholder://pending",
            account_status="active",
        ),
    )
    await db_session.commit()

    response = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "Secret123!"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["authenticated"] is True
    assert data["access_token"]

    stored = (
        await db_session.execute(select(User).where(User.email == email))
    ).scalar_one()
    assert stored.is_email_verified is True
