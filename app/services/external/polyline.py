"""Small Google encoded polyline helper used by mock and real routes."""

from __future__ import annotations


def encode_polyline(points: list[tuple[float, float]]) -> str:
    """Encode ``[(lat, lng), ...]`` using Google's polyline algorithm."""
    result: list[str] = []
    prev_lat = 0
    prev_lng = 0

    for lat, lng in points:
        lat_i = int(round(lat * 1e5))
        lng_i = int(round(lng * 1e5))
        result.append(_encode_value(lat_i - prev_lat))
        result.append(_encode_value(lng_i - prev_lng))
        prev_lat = lat_i
        prev_lng = lng_i

    return "".join(result)


def _encode_value(value: int) -> str:
    value = ~(value << 1) if value < 0 else value << 1
    chunks: list[str] = []
    while value >= 0x20:
        chunks.append(chr((0x20 | (value & 0x1F)) + 63))
        value >>= 5
    chunks.append(chr(value + 63))
    return "".join(chunks)
