"""Integration tests for auth endpoints."""

from __future__ import annotations

import uuid

import pytest


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
