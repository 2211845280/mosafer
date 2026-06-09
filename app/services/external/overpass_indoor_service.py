"""Fetch and normalize indoor OSM data via Overpass (OpenLevelUp-style source)."""

from __future__ import annotations

import structlog
from httpx import AsyncClient, Timeout

from app.schemas.indoor_map import (
    IndoorFeature,
    IndoorLevel,
    IndoorMapBounds,
    IndoorMapResponse,
    IndoorPointOfInterest,
)
from app.services.istanbul_indoor_fallback import IST_IATA, IST_NAME, build_istanbul_indoor_map

logger = structlog.get_logger(__name__)

OVERPASS_URL = "https://overpass-api.de/api/interpreter"

# Bounding box around Istanbul Airport (south, west, north, east)
IST_BBOX = (41.255, 28.720, 41.295, 28.790)

_LEVEL_LABELS: dict[str, str] = {
    "-1": "Arrivals / Lower Level",
    "0": "Main Terminal",
    "1": "Departures / Gates",
    "2": "Upper Level",
}


def _parse_level(raw: str | None) -> str | None:
    if not raw:
        return None
    value = raw.strip().split(";")[0].split("-")[0].split(",")[0]
    return value if value else None


def _feature_type(tags: dict[str, str]) -> str:
    indoor = tags.get("indoor", "")
    room = tags.get("room", "")
    highway = tags.get("highway", "")
    amenity = tags.get("amenity", "")
    shop = tags.get("shop", "")

    if tags.get("aeroway") == "gate" or "gate" in tags.get("ref", "").lower():
        return "gate"
    if indoor == "corridor" or highway == "footway":
        return "corridor"
    if room in {"toilets", "toilet"} or amenity in {"toilets", "toilet"}:
        return "toilet"
    if shop or tags.get("shop") or indoor == "room" and shop:
        return "shop"
    if amenity in {"restaurant", "fast_food", "cafe", "food_court"}:
        return "food"
    if amenity == "lounge" or "lounge" in tags.get("name", "").lower():
        return "lounge"
    if indoor in {"area", "room"}:
        return "room"
    return "room"


def _normalize_points(
    coords: list[tuple[float, float]],
    min_lat: float,
    min_lon: float,
    lat_span: float,
    lon_span: float,
) -> list[list[float]]:
    points: list[list[float]] = []
    for lat, lon in coords:
        x = ((lon - min_lon) / lon_span) * 1000 if lon_span else 500
        y = (1 - (lat - min_lat) / lat_span) * 1000 if lat_span else 500
        points.append([round(x, 2), round(y, 2)])
    return points


def _build_overpass_query() -> str:
    south, west, north, east = IST_BBOX
    return f"""
[out:json][timeout:25];
(
  way["level"]({south},{west},{north},{east});
  way["indoor"]({south},{west},{north},{east});
  node["level"]["name"]({south},{west},{north},{east});
  node["shop"]({south},{west},{north},{east});
  node["amenity"]({south},{west},{north},{east});
);
out body;
>;
out skel qt;
"""


def _parse_overpass_elements(data: dict) -> IndoorMapResponse | None:
    elements = data.get("elements", [])
    if not elements:
        return None

    nodes: dict[int, tuple[float, float]] = {}
    ways: list[dict] = []
    poi_nodes: list[dict] = []

    for el in elements:
        if el.get("type") == "node" and "lat" in el and "lon" in el:
            nodes[el["id"]] = (el["lat"], el["lon"])
            tags = el.get("tags") or {}
            if tags.get("name") and _parse_level(tags.get("level")):
                poi_nodes.append(el)

    for el in elements:
        if el.get("type") == "way":
            ways.append(el)

    if not ways:
        return None

    all_lats: list[float] = []
    all_lons: list[float] = []
    for nid, (lat, lon) in nodes.items():
        all_lats.append(lat)
        all_lons.append(lon)

    if not all_lats:
        return None

    min_lat, max_lat = min(all_lats), max(all_lats)
    min_lon, max_lon = min(all_lons), max(all_lons)
    lat_span = max(max_lat - min_lat, 0.0001)
    lon_span = max(max_lon - min_lon, 0.0001)

    level_ids: set[str] = set()
    features: list[IndoorFeature] = []
    pois: list[IndoorPointOfInterest] = []

    for way in ways:
        tags = way.get("tags") or {}
        level = _parse_level(tags.get("level"))
        if level is None:
            continue
        level_ids.add(level)

        node_refs = way.get("nodes") or []
        coords = [nodes[nid] for nid in node_refs if nid in nodes]
        if len(coords) < 2:
            continue

        points = _normalize_points(coords, min_lat, min_lon, lat_span, lon_span)
        ftype = _feature_type(tags)
        label = tags.get("name") or tags.get("ref")

        features.append(
            IndoorFeature(
                id=f"way-{way['id']}",
                type=ftype,
                level=level,
                label=label,
                points=points,
            )
        )

    for node in poi_nodes:
        tags = node.get("tags") or {}
        level = _parse_level(tags.get("level"))
        if level is None:
            continue
        lat, lon = node["lat"], node["lon"]
        x, y = _normalize_points([(lat, lon)], min_lat, min_lon, lat_span, lon_span)[0]
        pois.append(
            IndoorPointOfInterest(
                id=f"node-{node['id']}",
                type=_feature_type(tags),
                level=level,
                label=tags.get("name", "POI"),
                x=x,
                y=y,
                lat=lat,
                lng=lon,
            )
        )

    if len(features) < 5:
        return None

    levels = [
        IndoorLevel(id=lid, label=_LEVEL_LABELS.get(lid, f"Level {lid}"))
        for lid in sorted(level_ids, key=lambda v: float(v) if v.lstrip("-").isdigit() else 99)
    ]
    default_level = "0" if any(l.id == "0" for l in levels) else levels[0].id

    return IndoorMapResponse(
        airport_iata=IST_IATA,
        airport_name=IST_NAME,
        default_level=default_level,
        levels=levels,
        bounds=IndoorMapBounds(),
        features=features[:200],
        pois=pois[:50],
        source="overpass",
        is_fallback=False,
        supported=True,
        message="Live indoor data from OpenStreetMap via Overpass.",
    )


async def fetch_istanbul_indoor_map(*, highlight_gate: str | None = None) -> IndoorMapResponse:
    """Try Overpass; fall back to curated IST layout."""
    query = _build_overpass_query()
    try:
        async with AsyncClient(timeout=Timeout(30.0)) as client:
            response = await client.post(OVERPASS_URL, data={"data": query})
            response.raise_for_status()
            parsed = _parse_overpass_elements(response.json())
            if parsed is not None:
                from app.services.istanbul_indoor_geo import enrich_indoor_map

                parsed.highlight_gate = highlight_gate
                return enrich_indoor_map(parsed, gate=highlight_gate)
    except Exception as exc:
        logger.warning("overpass_indoor.fetch_failed", error=str(exc))

    from app.services.istanbul_indoor_geo import enrich_indoor_map

    fallback = build_istanbul_indoor_map(highlight_gate=highlight_gate)
    fallback.message = "Using curated Istanbul Airport layout (Overpass unavailable or sparse)."
    return enrich_indoor_map(fallback, gate=highlight_gate)
