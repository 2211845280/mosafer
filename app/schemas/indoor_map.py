"""Pydantic schemas for native indoor airport maps."""

from __future__ import annotations

from pydantic import BaseModel, Field


class IndoorMapBounds(BaseModel):
    """Normalized drawing bounds (0–1000 space)."""

    min_x: float = 0.0
    min_y: float = 0.0
    max_x: float = 1000.0
    max_y: float = 1000.0


class GeoPoint(BaseModel):
    """WGS84 point for map markers and routes."""

    lat: float
    lng: float
    label: str | None = None


class IndoorMapViewport(BaseModel):
    """OpenLevelUp / Leaflet-compatible map center."""

    center_lat: float
    center_lng: float
    zoom: int = 17
    open_levelup_level: str = "1"


class IndoorLevel(BaseModel):
    id: str
    label: str


class IndoorFeature(BaseModel):
    """Polygon or polyline feature on a floor plan."""

    id: str
    type: str = Field(description="corridor | room | gate | shop | lounge | food | toilet | hall")
    level: str
    label: str | None = None
    points: list[list[float]] = Field(
        description="List of [x, y] coordinates in normalized map space",
    )


class IndoorPointOfInterest(BaseModel):
    id: str
    type: str
    level: str
    label: str
    x: float
    y: float
    lat: float | None = None
    lng: float | None = None


class IndoorMapResponse(BaseModel):
    airport_iata: str
    airport_name: str
    default_level: str
    levels: list[IndoorLevel]
    bounds: IndoorMapBounds
    features: list[IndoorFeature]
    pois: list[IndoorPointOfInterest] = Field(default_factory=list)
    source: str = Field(description="overpass | fallback")
    is_fallback: bool = False
    supported: bool = True
    message: str | None = None
    highlight_gate: str | None = None
    highlight_category: str | None = None
    highlight_pois: list[IndoorPointOfInterest] = Field(default_factory=list)
    viewport: IndoorMapViewport | None = None
    user_location: GeoPoint | None = None
    gate_location: GeoPoint | None = None
    route_points: list[GeoPoint] = Field(default_factory=list)
