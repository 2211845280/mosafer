"""Capture full-page Mosafer web screenshots for documentation."""

from __future__ import annotations

import os
from pathlib import Path

from playwright.sync_api import Page, sync_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "screenshots" / "web"

WEB_BASE_URL = os.environ.get("WEB_SCREENSHOT_URL", "http://127.0.0.1:3000")
LOCALE = os.environ.get("WEB_SCREENSHOT_LOCALE", "ar")
VIEWPORT_WIDTH = int(os.environ.get("WEB_SCREENSHOT_WIDTH", "1440"))
WAIT_MS = int(os.environ.get("WEB_SCREENSHOT_WAIT_MS", "4000"))
WEB_SCREENSHOT_EMAIL = os.environ.get("WEB_SCREENSHOT_EMAIL", "")
WEB_SCREENSHOT_PASSWORD = os.environ.get("WEB_SCREENSHOT_PASSWORD", "")


def capture(page: Page, url: str, out_path: Path, *, full_page: bool) -> None:
    page.set_viewport_size({"width": VIEWPORT_WIDTH, "height": 900})
    page.goto(url, wait_until="networkidle", timeout=60_000)
    page.wait_for_timeout(WAIT_MS)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    page.screenshot(path=str(out_path), full_page=full_page)
    print(f"Saved {out_path} ({out_path.stat().st_size:,} bytes)")


def try_web_login(page: Page, base: str, locale: str) -> bool:
    email = WEB_SCREENSHOT_EMAIL.strip()
    password = WEB_SCREENSHOT_PASSWORD
    if not email or not password:
        return False

    page.goto(f"{base}/{locale}/login", wait_until="networkidle", timeout=60_000)
    page.wait_for_timeout(1500)
    page.locator('input[type="email"]').fill(email)
    page.locator('input[type="password"]').fill(password)
    page.locator('button[type="submit"]').click()
    page.wait_for_timeout(3500)
    return "/login" not in page.url


def main() -> int:
    base = WEB_BASE_URL.rstrip("/")
    locale = LOCALE.strip("/")

    shots: list[tuple[str, Path, bool, bool]] = [
        (f"{base}/{locale}", OUT_DIR / "01-homepage-full.png", True, False),
        (f"{base}/{locale}/login", OUT_DIR / "02-login.png", False, False),
        (f"{base}/{locale}/profile", OUT_DIR / "03-profile-full.png", True, True),
    ]

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(locale=locale)
        logged_in = try_web_login(page, base, locale)
        if WEB_SCREENSHOT_EMAIL and not logged_in:
            print("Warning: web login failed; profile capture may show guest state.")

        for url, path, full_page, needs_auth in shots:
            if needs_auth and not logged_in:
                print(f"Skipped {path.name} (set WEB_SCREENSHOT_EMAIL/PASSWORD)")
                continue
            capture(page, url, path, full_page=full_page)
        browser.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
