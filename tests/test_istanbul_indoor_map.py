"""Tests for Istanbul indoor map fallback."""

from app.services.istanbul_indoor_fallback import build_istanbul_indoor_map


def test_istanbul_fallback_has_levels():
    data = build_istanbul_indoor_map()
    assert data.airport_iata == "IST"
    assert data.supported is True
    assert len(data.levels) == 3
    assert data.default_level == "0"


def test_istanbul_fallback_features_per_level():
    data = build_istanbul_indoor_map(highlight_gate="G12")
    level_ids = {level.id for level in data.levels}
    assert level_ids == {"-1", "0", "1"}
    assert any(f.label == "G12" for f in data.features)
    assert data.highlight_gate == "G12"
