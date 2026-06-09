"""Integration tests for password reset endpoints."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from unittest.mock import AsyncMock, patch

import pytest
from sqlalchemy import select

from app.core.security import hash_password, verify_password
from app.models.users import User


@pytest.mark.asyncio
async def test_forgot_password_always_200(prepare_schema, client):
    response = await client.post(
        "/api/v1/auth/forgot-password",
        json={"email": "nobody@example.com"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


@pytest.mark.asyncio
async def test_forgot_password_sends_for_existing_user(prepare_schema, client, db_session):
    email = f"reset-{uuid.uuid4().hex[:8]}@example.com"
    user = User(
        email=email,
        password_hash=hash_password("OldSecret123!"),
        is_active=True,
        is_email_verified=True,
    )
    db_session.add(user)
    await db_session.commit()

    with patch(
        "app.api.v1.auth.get_email_service",
    ) as mock_get_service:
        mock_service = AsyncMock()
        mock_service.send_password_reset.return_value = (True, None)
        mock_get_service.return_value = mock_service

        response = await client.post(
            "/api/v1/auth/forgot-password",
            json={"email": email},
        )

    assert response.status_code == 200
    mock_service.send_password_reset.assert_called_once()

    refreshed = (
        await db_session.execute(select(User).where(User.email == email))
    ).scalar_one()
    assert refreshed.password_reset_token_hash is not None
    assert refreshed.password_reset_expires_at is not None


@pytest.mark.asyncio
async def test_reset_password_valid_token(prepare_schema, client, db_session):
    import hashlib
    import secrets

    email = f"reset-{uuid.uuid4().hex[:8]}@example.com"
    raw_token = secrets.token_urlsafe(48)
    token_hash = hashlib.sha256(raw_token.encode()).hexdigest()
    user = User(
        email=email,
        password_hash=hash_password("OldSecret123!"),
        is_active=True,
        is_email_verified=True,
        password_reset_token_hash=token_hash,
        password_reset_expires_at=datetime.now(UTC) + timedelta(minutes=30),
    )
    db_session.add(user)
    await db_session.commit()

    response = await client.post(
        "/api/v1/auth/reset-password",
        json={"token": raw_token, "new_password": "NewSecret456!"},
    )
    assert response.status_code == 200
    assert response.json()["message"] == "Password reset successfully"

    refreshed = (
        await db_session.execute(select(User).where(User.email == email))
    ).scalar_one()
    assert refreshed.password_reset_token_hash is None
    assert refreshed.password_reset_expires_at is None
    assert verify_password("NewSecret456!", refreshed.password_hash)


@pytest.mark.asyncio
async def test_reset_password_rejects_expired_token(prepare_schema, client, db_session):
    import hashlib
    import secrets

    email = f"reset-{uuid.uuid4().hex[:8]}@example.com"
    raw_token = secrets.token_urlsafe(48)
    token_hash = hashlib.sha256(raw_token.encode()).hexdigest()
    user = User(
        email=email,
        password_hash=hash_password("OldSecret123!"),
        is_active=True,
        is_email_verified=True,
        password_reset_token_hash=token_hash,
        password_reset_expires_at=datetime.now(UTC) - timedelta(minutes=1),
    )
    db_session.add(user)
    await db_session.commit()

    response = await client.post(
        "/api/v1/auth/reset-password",
        json={"token": raw_token, "new_password": "NewSecret456!"},
    )
    assert response.status_code == 400
    assert "Invalid or expired" in response.json()["detail"]


@pytest.mark.asyncio
async def test_reset_password_rejects_invalid_token(prepare_schema, client):
    response = await client.post(
        "/api/v1/auth/reset-password",
        json={"token": "not-a-valid-token", "new_password": "NewSecret456!"},
    )
    assert response.status_code == 400
