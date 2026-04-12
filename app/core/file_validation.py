"""File signature (magic bytes) validation helpers."""

from __future__ import annotations

MAGIC_HEADERS: dict[str, tuple[bytes, ...]] = {
    "image/jpeg": (b"\xff\xd8\xff",),
    "image/png": (b"\x89PNG\r\n\x1a\n",),
    "image/webp": (b"RIFF",),
    "application/pdf": (b"%PDF",),
}


def has_valid_magic_bytes(content: bytes, content_type: str) -> bool:
    """Validate file starts with expected magic bytes for a content type."""
    signatures = MAGIC_HEADERS.get(content_type)
    if not signatures:
        return False
    if content_type == "image/webp":
        return content.startswith(b"RIFF") and b"WEBP" in content[:16]
    return any(content.startswith(sig) for sig in signatures)
