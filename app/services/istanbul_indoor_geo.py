"""WGS84 coordinates for IST indoor map (OpenLevelUp / OSM-aligned demo).

Coordinates target Istanbul Airport international departures (G concourse)
and match the OpenLevelUp viewport at zoom 17.
"""

from __future__ import annotations

from dataclasses import dataclass

from app.schemas.indoor_map import GeoPoint, IndoorMapResponse, IndoorMapViewport, IndoorPointOfInterest
# OpenLevelUp slippy-map viewport (same as openlevelup.net/#17/41.2622/28.7425)
VIEWPORT_CENTER_LAT = 41.2622
VIEWPORT_CENTER_LNG = 28.7425
VIEWPORT_ZOOM = 17
OPEN_LEVELUP_LEVEL = "1"

# Landmarks — curated near OSM indoor features at IST terminal
DUTY_FREE_LAT = 41.26305
DUTY_FREE_LNG = 28.74425
USER_NEAR_DUTY_FREE_LAT = 41.26278
USER_NEAR_DUTY_FREE_LNG = 28.74355
SECURITY_LAT = 41.26345
SECURITY_LNG = 28.74185
CONCOURSE_SPINE_LAT = 41.26235
CONCOURSE_SPINE_LNG = 28.74610

# Gate positions along G concourse (WGS84)
GATE_COORDS: dict[str, tuple[float, float]] = {
    "G1": (41.26355, 28.73940),
    "G2": (41.26325, 28.74080),
    "G3": (41.26295, 28.74220),
    "G4": (41.26270, 28.74360),
    "G5": (41.26250, 28.74500),
    "G6": (41.26230, 28.74640),
    "G7": (41.26215, 28.74750),
    "G8": (41.26205, 28.74820),
    "G12": (41.26195, 28.74895),
}

AMENITY_COORDS: dict[str, tuple[float, float, str, str]] = {
  # id_suffix: (lat, lng, type, label)
    "coffee-spine": (41.26240, 28.74580, "coffee", "Coffee Point"),
    "coffee-g12": (41.26210, 28.74840, "coffee", "Starbucks Gate Area"),
    "coffee-g6": (41.26225, 28.74610, "coffee", "Cafe G6"),
    "bites-spine": (41.26250, 28.74550, "food", "Quick Bites"),
    "bites-g12": (41.26185, 28.74870, "food", "Grab & Go G12"),
    "bites-g4": (41.26265, 28.74380, "food", "Snack Bar G4"),
}


@dataclass(frozen=True)
class _GeoRoute:
    points: list[GeoPoint]
    user: GeoPoint
    gate: GeoPoint


def gate_lat_lng(gate: str | None) -> tuple[float, float]:
    normalized = (gate or "G12").strip().upper()
    return GATE_COORDS.get(normalized, GATE_COORDS["G12"])


def build_route_to_gate(gate: str | None) -> _GeoRoute:
    """Walking simulation: near duty free → concourse → gate."""
    g_lat, g_lng = gate_lat_lng(gate)
    gate_label = (gate or "G12").strip().upper()
    user = GeoPoint(
        lat=USER_NEAR_DUTY_FREE_LAT,
        lng=USER_NEAR_DUTY_FREE_LNG,
        label="You",
    )
    gate_point = GeoPoint(lat=g_lat, lng=g_lng, label=gate_label)
    points = [
        user,
        GeoPoint(lat=DUTY_FREE_LAT, lng=DUTY_FREE_LNG, label="Duty Free"),
        GeoPoint(lat=CONCOURSE_SPINE_LAT, lng=CONCOURSE_SPINE_LNG, label="Concourse"),
        gate_point,
    ]
    return _GeoRoute(points=points, user=user, gate=gate_point)


def default_viewport() -> IndoorMapViewport:
    return IndoorMapViewport(
        center_lat=VIEWPORT_CENTER_LAT,
        center_lng=VIEWPORT_CENTER_LNG,
        zoom=VIEWPORT_ZOOM,
        open_levelup_level=OPEN_LEVELUP_LEVEL,
    )


def attach_geo_to_poi(poi: IndoorPointOfInterest) -> IndoorPointOfInterest:
    """Fill lat/lng on known demo POIs."""
    if poi.lat is not None and poi.lng is not None:
        return poi

    label_upper = poi.label.strip().upper()
    if poi.type == "you":
        return poi.model_copy(
            update={"lat": USER_NEAR_DUTY_FREE_LAT, "lng": USER_NEAR_DUTY_FREE_LNG},
        )
    if "duty" in poi.label.lower():
        return poi.model_copy(update={"lat": DUTY_FREE_LAT, "lng": DUTY_FREE_LNG})

    if poi.type == "gate" or label_upper in GATE_COORDS:
        lat, lng = gate_lat_lng(label_upper)
        return poi.model_copy(update={"lat": lat, "lng": lng})

    for suffix, (lat, lng, _ptype, name) in AMENITY_COORDS.items():
        if suffix in poi.id or poi.label == name:
            return poi.model_copy(update={"lat": lat, "lng": lng})

    return poi


def enrich_indoor_map(response: IndoorMapResponse, *, gate: str | None) -> IndoorMapResponse:
    """Add viewport, user location, gate, route, and WGS84 on POIs."""
    route = build_route_to_gate(gate)
    pois = [attach_geo_to_poi(p) for p in response.pois]
    highlight_pois = [attach_geo_to_poi(p) for p in response.highlight_pois]

    return response.model_copy(
        update={
            "viewport": response.viewport or default_viewport(),
            "user_location": route.user,
            "gate_location": route.gate,
            "route_points": route.points,
            "pois": pois,
            "highlight_pois": highlight_pois,
        },
    )


def haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Approximate distance in meters for nearest-POI selection."""
    import math

    r = 6_371_000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(p1) * math.cos(p2) * math.sin(dlng / 2) ** 2
    )
    return 2 * r * math.asin(math.sqrt(a))
