"""Nearest amenity POI selection for IST indoor map highlights."""

from __future__ import annotations

import math

from app.schemas.indoor_map import IndoorMapResponse, IndoorPointOfInterest
from app.services.istanbul_indoor_geo import gate_lat_lng, haversine_m

# Gate rectangle origins on level 1 (same as istanbul_indoor_fallback gate_layout).
_GATE_LAYOUT: dict[str, tuple[float, float]] = {
    "G1": (120, 180),
    "G2": (320, 180),
    "G3": (520, 180),
    "G4": (720, 180),
    "G5": (120, 480),
    "G6": (320, 480),
    "G7": (520, 480),
    "G8": (720, 480),
    "G12": (820, 480),
}

_CATEGORY_TYPES: dict[str, frozenset[str]] = {
    "coffee": frozenset({"coffee", "cafe"}),
    "food": frozenset({"food", "quick_bites", "snack", "restaurant"}),
}


def _gate_center(gate: str) -> tuple[float, float, str]:
    normalized = gate.strip().upper()
    if normalized in _GATE_LAYOUT:
        gx, gy = _GATE_LAYOUT[normalized]
        return gx + 60.0, gy + 40.0, "1"
    for poi in _fallback_gate_pois():
        if poi.label.strip().upper() == normalized:
            return poi.x, poi.y, poi.level
    return 500.0, 400.0, "1"


def _fallback_gate_pois() -> list[IndoorPointOfInterest]:
    return [
        IndoorPointOfInterest(
            id="poi-g12",
            type="gate",
            level="1",
            label="G12",
            x=880,
            y=520,
        ),
    ]


def _distance(ax: float, ay: float, bx: float, by: float) -> float:
    return math.hypot(ax - bx, ay - by)


def _poi_distance_to_gate(
    poi: IndoorPointOfInterest,
    gate: str,
    gate_x: float,
    gate_y: float,
) -> float:
    if poi.lat is not None and poi.lng is not None:
        g_lat, g_lng = gate_lat_lng(gate)
        return haversine_m(poi.lat, poi.lng, g_lat, g_lng)
    return _distance(gate_x, gate_y, poi.x, poi.y)


def _matches_category(poi: IndoorPointOfInterest, category: str) -> bool:
    allowed = _CATEGORY_TYPES.get(category.lower())
    if allowed is None:
        return False
    poi_type = poi.type.lower()
    if poi_type in allowed:
        return True
    label = poi.label.lower()
    if category == "coffee":
        return "coffee" in label or "cafe" in label
    if category == "food":
        return any(token in label for token in ("bite", "food", "snack", "grill", "bakery"))
    return False


def select_nearest_highlight_pois(
    pois: list[IndoorPointOfInterest],
    *,
    gate: str | None,
    category: str | None,
    limit: int = 3,
) -> list[IndoorPointOfInterest]:
    """Return nearest POIs of the requested category relative to the gate."""
    if not category or not gate:
        return []

    gate_x, gate_y, _ = _gate_center(gate)
    candidates = [p for p in pois if _matches_category(p, category)]
    candidates.sort(
        key=lambda p: _poi_distance_to_gate(p, gate, gate_x, gate_y),
    )
    return candidates[:limit]


def apply_amenity_highlights(
    response: IndoorMapResponse,
    *,
    gate: str | None,
    category: str | None,
) -> IndoorMapResponse:
    """Attach highlight metadata to an indoor map response."""
    if not category:
        return response

    normalized = category.strip().lower()
    if normalized not in _CATEGORY_TYPES:
        return response.model_copy(
            update={
                "highlight_category": normalized,
                "highlight_pois": [],
            },
        )

    highlight_pois = select_nearest_highlight_pois(
        response.pois,
        gate=gate,
        category=normalized,
    )
    return response.model_copy(
        update={
            "highlight_category": normalized,
            "highlight_pois": highlight_pois,
        },
    )
