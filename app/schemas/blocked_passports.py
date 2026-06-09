"""Schemas for flight-level passport duplicate checks."""

from pydantic import BaseModel


class BlockedPassportsRead(BaseModel):
    blocked_passports: list[str]
