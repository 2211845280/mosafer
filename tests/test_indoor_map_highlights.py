"""Tests for IST indoor map amenity highlights."""

from __future__ import annotations

from app.services.istanbul_indoor_fallback import build_istanbul_indoor_map
from app.services.istanbul_indoor_highlights import apply_amenity_highlights


def test_coffee_highlight_near_g12():
    base = build_istanbul_indoor_map(highlight_gate="G12")
    result = apply_amenity_highlights(base, gate="G12", category="coffee")

    assert result.highlight_category == "coffee"
    assert len(result.highlight_pois) >= 1
    assert all(p.type == "coffee" or "coffee" in p.label.lower() for p in result.highlight_pois)
    assert result.highlight_pois[0].label == "Starbucks Gate Area"


def test_food_highlight_near_g12():
    base = build_istanbul_indoor_map(highlight_gate="G12")
    result = apply_amenity_highlights(base, gate="G12", category="food")

    assert result.highlight_category == "food"
    assert len(result.highlight_pois) >= 1
    assert result.highlight_pois[0].label == "Grab & Go G12"


def test_unknown_category_returns_empty_highlights():
    base = build_istanbul_indoor_map(highlight_gate="G12")
    result = apply_amenity_highlights(base, gate="G12", category="spa")

    assert result.highlight_category == "spa"
    assert result.highlight_pois == []
