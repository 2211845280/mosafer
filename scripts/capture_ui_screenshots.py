"""Capture Mosafer Flutter web screens and export Android-framed PNGs for docs."""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

from PIL import Image, ImageDraw
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "docs" / "screenshots" / "raw"
FRAMED_DIR = ROOT / "docs" / "screenshots" / "android"
DOCS_HTML = ROOT / "docs" / "app-ui-gallery.html"
DOCS_MD = ROOT / "docs" / "app-ui-screens.md"

BASE_URL = os.environ.get("SCREENSHOT_BASE_URL", "http://127.0.0.1:7357")
AUTH_BASE_URL = os.environ.get("SCREENSHOT_AUTH_URL", "http://127.0.0.1:7357")
APP_BASE_URL = os.environ.get("SCREENSHOT_APP_URL", "http://127.0.0.1:7358")
API_URL = "http://localhost:8001/api/v1/auth"
VIEWPORT = {"width": 412, "height": 915}
WAIT_MS = 5000
MIN_SCREENSHOT_BYTES = 30_000

ROUTE_WAIT_MS = {
    "/on-way": 8000,
    "/airport-indoor-map": 15000,
    "/packing": 6000,
}

ROUTE_LOAD_UNTIL = {
    "/packing": "load",
    "/on-way": "load",
    "/airport-indoor-map": "load",
}

SCREENS = [
    # Auth (public)
    ("01-login", "/login", False, "تسجيل الدخول", "Login"),
    ("02-register", "/register", False, "إنشاء حساب", "Register"),
    ("03-forgot-password", "/forgot-password", False, "نسيت كلمة المرور", "Forgot password"),
    ("04-reset-password", "/reset-password", False, "إعادة تعيين كلمة المرور", "Reset password"),
    # Main navigation
    ("05-explore", "/explore", True, "الرحلات", "Flights / Explore"),
    ("06-trips", "/trips", True, "رحلاتي", "My trips"),
    ("07-profile", "/profile", True, "الحساب", "Profile"),
    ("08-settings", "/settings", True, "الإعدادات", "Settings"),
    # Trip hub stages
    ("09-dashboard", "/dashboard", True, "في المنزل", "Home dashboard"),
    ("10-on-way", "/on-way", True, "في الطريق", "On the way"),
    ("11-airport", "/airport-experience", True, "في المطار", "Airport experience"),
    # Trip tools
    ("12-plan-departure", "/plan-departure", True, "خطة المغادرة", "Departure plan"),
    ("13-packing", "/packing", True, "قائمة التجهيز", "Packing list"),
    ("14-timeline", "/timeline", True, "الجدول الزمني", "Timeline"),
    ("15-trip-todos", "/trip-todos", True, "قائمة المهام", "Trip todos"),
    ("16-scan", "/scan", True, "مسح التذكرة", "Scan ticket"),
    ("17-notifications", "/notifications", True, "الإشعارات", "Notifications"),
    ("18-ticket-details", "/ticket-details", True, "تفاصيل التذكرة", "Ticket details"),
    ("19-edit-profile", "/edit-profile", True, "تعديل الملف", "Edit profile"),
    ("20-change-password", "/change-password", True, "تغيير كلمة المرور", "Change password"),
    ("21-deleted-trips", "/deleted-trips", True, "سلة المحذوفات", "Deleted trips"),
    ("22-indoor-map", "/airport-indoor-map", True, "خريطة المطار", "Indoor map"),
]


def frame_android(raw_path: Path, out_path: Path) -> None:
    """Wrap a screenshot inside a simple Android phone mockup."""
    screen = Image.open(raw_path).convert("RGBA")
    sw, sh = screen.size

    bezel = 14
    radius = 36
    frame_w = sw + bezel * 2
    frame_h = sh + bezel * 2 + 28  # room for chin

    frame = Image.new("RGBA", (frame_w, frame_h), (18, 22, 32, 255))
    draw = ImageDraw.Draw(frame)

    # Outer rounded body
    draw.rounded_rectangle(
        (0, 0, frame_w - 1, frame_h - 1),
        radius=radius,
        outline=(60, 68, 86, 255),
        width=3,
        fill=(24, 28, 38, 255),
    )

    # Screen area
    sx, sy = bezel, bezel + 10
    frame.paste(screen, (sx, sy))

    # Punch-hole camera
    cx = frame_w // 2
    draw.ellipse((cx - 9, 6, cx + 9, 24), fill=(10, 12, 18, 255))

    # Bottom gesture bar
    bar_w = 110
    bar_h = 5
    bx0 = (frame_w - bar_w) // 2
    by0 = frame_h - 18
    draw.rounded_rectangle(
        (bx0, by0, bx0 + bar_w, by0 + bar_h),
        radius=3,
        fill=(130, 138, 155, 220),
    )

    rgb = Image.new("RGB", frame.size, (245, 247, 250))
    rgb.paste(frame, mask=frame.split()[3])
    out_path.parent.mkdir(parents=True, exist_ok=True)
    rgb.save(out_path, "PNG", optimize=True)


def try_login(page, email: str, password: str) -> bool:
    """Attempt UI login on Flutter web."""
    page.goto(f"{BASE_URL}/login", wait_until="networkidle")
    page.wait_for_timeout(WAIT_MS)

    # Enable Flutter semantics if the helper button is present.
    try:
        page.get_by_role("button", name="Enable accessibility").click(timeout=2000)
        page.wait_for_timeout(800)
    except Exception:
        pass

    # Coordinate taps for the login form (mobile viewport).
    page.mouse.click(206, 360)
    page.wait_for_timeout(300)
    page.keyboard.press("Control+A")
    page.keyboard.type(email, delay=40)
    page.wait_for_timeout(300)

    page.mouse.click(206, 455)
    page.wait_for_timeout(300)
    page.keyboard.press("Control+A")
    page.keyboard.type(password, delay=40)
    page.wait_for_timeout(300)

    page.mouse.click(206, 560)
    page.wait_for_timeout(3500)

    return "/login" not in page.url


def inject_tokens(page, email: str, password: str) -> bool:
    """Login via API and persist tokens for flutter_secure_storage web."""
    script = """
    async ({ apiUrl, email, password }) => {
      const res = await fetch(apiUrl + '/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      if (!res.ok) return false;
      const data = await res.json();
      const access = data.access_token;
      const refresh = data.refresh_token;
      if (!access) return false;

      // flutter_secure_storage (web) plain fallback keys used in dev.
      localStorage.setItem('auth_token', access);
      localStorage.setItem('refresh_token', refresh || '');

      // Encrypted storage map shape (best-effort for newer plugin builds).
      const map = { auth_token: access, refresh_token: refresh || '' };
      localStorage.setItem('FlutterSecureStorage', JSON.stringify(map));
      return true;
    }
    """
    try:
        return bool(
            page.evaluate(
                script,
                {"apiUrl": "http://localhost:8001/api/v1", "email": email, "password": password},
            )
        )
    except Exception:
        return False


def _screen_url(base_url: str, route: str) -> str:
    clean = route if route.startswith("/") else f"/{route}"
    return f"{base_url.rstrip('/')}/#{clean}"


def capture(page, slug: str, route: str, base_url: str) -> Path:
    raw_path = RAW_DIR / f"{slug}.png"
    wait_ms = ROUTE_WAIT_MS.get(route, WAIT_MS)
    load_until = ROUTE_LOAD_UNTIL.get(route, "networkidle")
    for attempt in range(4):
        page.goto(
            _screen_url(base_url, route),
            wait_until=load_until,
            timeout=60_000,
        )
        page.wait_for_timeout(wait_ms)
        page.screenshot(path=str(raw_path), full_page=False)
        if raw_path.stat().st_size >= MIN_SCREENSHOT_BYTES:
            break
        page.wait_for_timeout(2000)
        print(f"retry {slug} attempt {attempt + 1} ({raw_path.stat().st_size} bytes)")
    framed_path = FRAMED_DIR / f"{slug}.png"
    frame_android(raw_path, framed_path)
    return framed_path


def write_docs(captured: list[tuple[str, str, str, str]]) -> None:
    cards = []
    md_lines = [
        "# واجهات تطبيق مسافر (Mosafer)",
        "",
        "لقطات ملونة داخل إطار هاتف أندرويد لاستخدامها في التوثيق.",
        "",
        "| # | الشاشة (عربي) | Screen (EN) | المعاينة |",
        "|---:|---|---|---|",
    ]

    for index, (slug, ar, en, rel) in enumerate(captured, start=1):
        md_lines.append(f"| {index} | {ar} | {en} | ![{ar}]({rel}) |")
        cards.append(
            f"""
      <article class="card">
        <div class="phone-wrap">
          <img src="{rel}" alt="{ar}" loading="lazy" />
        </div>
        <h3>{index}. {ar}</h3>
        <p>{en}</p>
      </article>"""
        )

    DOCS_MD.write_text("\n".join(md_lines) + "\n", encoding="utf-8")

    html = f"""<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>معرض واجهات مسافر</title>
  <style>
    :root {{
      --bg: #f3f6fb;
      --card: #ffffff;
      --text: #1b2433;
      --muted: #5b667a;
      --accent: #2f6df6;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      font-family: "Segoe UI", Tahoma, sans-serif;
      background: linear-gradient(180deg, #eef3ff 0%, var(--bg) 220px);
      color: var(--text);
    }}
    header {{
      padding: 32px 24px 12px;
      text-align: center;
    }}
    header h1 {{ margin: 0 0 8px; font-size: 1.8rem; }}
    header p {{ margin: 0; color: var(--muted); }}
    .grid {{
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
      gap: 22px;
      padding: 24px;
      max-width: 1400px;
      margin: 0 auto 40px;
    }}
    .card {{
      background: var(--card);
      border-radius: 18px;
      padding: 16px;
      box-shadow: 0 10px 30px rgba(20, 34, 66, 0.08);
    }}
    .phone-wrap {{
      display: flex;
      justify-content: center;
      margin-bottom: 12px;
    }}
    .phone-wrap img {{
      width: 220px;
      height: auto;
      display: block;
    }}
    .card h3 {{ margin: 0 0 6px; font-size: 1rem; }}
    .card p {{ margin: 0; color: var(--muted); font-size: 0.9rem; }}
  </style>
</head>
<body>
  <header>
    <h1>معرض واجهات تطبيق مسافر</h1>
    <p>لقطات ملونة داخل إطار أندرويد — {len(captured)} شاشة</p>
  </header>
  <section class="grid">{''.join(cards)}
  </section>
</body>
</html>
"""
    DOCS_HTML.write_text(html, encoding="utf-8")


def _write_previews() -> None:
    """Create smaller PNG previews for quick IDE viewing."""
    preview_dir = ROOT / "docs" / "screenshots" / "previews"
    preview_dir.mkdir(parents=True, exist_ok=True)
    for src in sorted(FRAMED_DIR.glob("*.png")):
        img = Image.open(src)
        width, height = img.size
        new_width = 420
        new_height = int(height * new_width / width)
        resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        resized.save(preview_dir / src.name, format="PNG")


def main() -> int:
    email = sys.argv[1] if len(sys.argv) > 1 else "docscreens@test.com"
    password = sys.argv[2] if len(sys.argv) > 2 else "DocTest123!"

    RAW_DIR.mkdir(parents=True, exist_ok=True)
    FRAMED_DIR.mkdir(parents=True, exist_ok=True)

    captured: list[tuple[str, str, str, str]] = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport=VIEWPORT,
            device_scale_factor=2,
            locale="ar",
            color_scheme="dark",
        )
        page = context.new_page()

        # Phase 1 — auth screens (normal app, not auto-logged-in).
        for slug, route, needs_auth, ar, en in SCREENS:
            if needs_auth:
                continue
            try:
                framed = capture(page, slug, route, AUTH_BASE_URL)
                rel = framed.relative_to(ROOT / "docs").as_posix()
                captured.append((slug, ar, en, rel))
                print(f"ok {slug}")
            except Exception as exc:
                print(f"fail {slug}: {exc}")

        # Phase 2 — in-app screens (Flutter started with SCREENSHOT_MODE=true).
        for slug, route, needs_auth, ar, en in SCREENS:
            if not needs_auth:
                continue
            try:
                framed = capture(page, slug, route, APP_BASE_URL)
                rel = framed.relative_to(ROOT / "docs").as_posix()
                captured.append((slug, ar, en, rel))
                print(f"ok {slug}")
            except Exception as exc:
                print(f"fail {slug}: {exc}")

        browser.close()

    if not captured:
        print("No screenshots captured. Is Flutter web running on port 7357?")
        return 1

    write_docs(captured)
    _write_previews()
    print(f"Saved {len(captured)} screens -> {FRAMED_DIR}")
    print(f"Gallery: {DOCS_HTML}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
