"""Generate Mosafer launcher icons and splash assets from the brand logo."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BRAND_DIR = ROOT / "assets/images/brand"
LOGO_PATH = BRAND_DIR / "mosafer_logo.png"


def square_crop(image: Image.Image) -> Image.Image:
    width, height = image.size
    side = min(width, height)
    left = (width - side) // 2
    top = (height - side) // 2
    return image.crop((left, top, left + side, top + side))


def resize_logo(size: int, source: Image.Image) -> Image.Image:
    cropped = square_crop(source)
    return cropped.resize((size, size), Image.Resampling.LANCZOS)


def save_png(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG", optimize=True)


def main() -> None:
    source = Image.open(LOGO_PATH).convert("RGB")
    master = resize_logo(1024, source)
    save_png(LOGO_PATH, master)

    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    res_dir = ROOT / "android/app/src/main/res"
    for folder, size in android_sizes.items():
        save_png(res_dir / folder / "ic_launcher.png", resize_logo(size, source))

    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((ios_dir / "Contents.json").read_text(encoding="utf-8"))
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        base = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].replace("x", ""))
        size = int(base * scale)
        save_png(ios_dir / filename, resize_logo(size, source))

    save_png(res_dir / "drawable/splash_logo.png", resize_logo(512, source))
    print("Generated brand icons from mosafer_logo.png")


if __name__ == "__main__":
    main()
