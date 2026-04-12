"""Generic pagination response schema."""

from __future__ import annotations

from math import ceil

from pydantic import BaseModel


class PaginatedResponse[T](BaseModel):
    """Wrapper for paginated list responses."""

    items: list[T]
    total: int
    page: int
    page_size: int
    total_pages: int

    @classmethod
    def create(
        cls, *, items: list[T], total: int, page: int, page_size: int
    ) -> PaginatedResponse[T]:
        return cls(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            total_pages=ceil(total / page_size) if page_size > 0 else 0,
        )
