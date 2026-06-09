#!/usr/bin/env python3
"""Seed IST outbound review trips for the demo traveler account."""

from __future__ import annotations

import asyncio
import sys

from app.db.database import AsyncSessionLocal
from app.seed.istanbul_review_trips import seed_istanbul_review_trips


async def main() -> int:
    async with AsyncSessionLocal() as session:
        result = await seed_istanbul_review_trips(session)

    print("Istanbul review seed complete.")
    print(f"  Login: {result['email']} / {result['password']}")
    print(f"  Created: {len(result['created'])} trip(s)")
    if result["created"]:
        for pid in result["created"]:
            print(f"    + {pid}")
    if result["skipped"]:
        print(f"  Skipped (already present): {len(result['skipped'])}")
    print(f"  Total configured: {result['total_trips']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
