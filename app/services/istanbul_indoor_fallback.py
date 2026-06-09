"""Curated indoor map layout for Istanbul Airport (IST) demo."""

from __future__ import annotations

from app.schemas.indoor_map import (
    IndoorFeature,
    IndoorLevel,
    IndoorMapBounds,
    IndoorMapResponse,
    IndoorPointOfInterest,
)
from app.services.istanbul_gate_data import IST_DEMO_GATES

IST_IATA = "IST"
IST_NAME = "Istanbul Airport"

_LEVELS = [
    IndoorLevel(id="-1", label="Arrivals / Lower Level"),
    IndoorLevel(id="0", label="Main Terminal"),
    IndoorLevel(id="1", label="Departures / Gates"),
]


def _rect(x: float, y: float, w: float, h: float) -> list[list[float]]:
    return [
        [x, y],
        [x + w, y],
        [x + w, y + h],
        [x, y + h],
        [x, y],
    ]


def _build_features() -> list[IndoorFeature]:
    features: list[IndoorFeature] = []

    # Level -1 — Arrivals
    features.extend(
        [
            IndoorFeature(
                id="arrivals-hall",
                type="hall",
                level="-1",
                label="Arrivals Hall",
                points=_rect(80, 120, 840, 320),
            ),
            IndoorFeature(
                id="arrivals-baggage",
                type="room",
                level="-1",
                label="Baggage Claim",
                points=_rect(120, 480, 760, 180),
            ),
            IndoorFeature(
                id="arrivals-corridor",
                type="corridor",
                level="-1",
                label="Exit Corridor",
                points=[[460, 440], [540, 440], [540, 480], [460, 480], [460, 440]],
            ),
        ]
    )

    # Level 0 — Main terminal
    features.extend(
        [
            IndoorFeature(
                id="main-central",
                type="hall",
                level="0",
                label="Central Atrium",
                points=_rect(200, 200, 600, 400),
            ),
            IndoorFeature(
                id="main-duty-free",
                type="shop",
                level="0",
                label="Duty Free",
                points=_rect(820, 220, 140, 360),
            ),
            IndoorFeature(
                id="main-food",
                type="food",
                level="0",
                label="Food Court",
                points=_rect(40, 220, 140, 360),
            ),
            IndoorFeature(
                id="main-lounge",
                type="lounge",
                level="0",
                label="IGA Lounge",
                points=_rect(820, 620, 140, 120),
            ),
            IndoorFeature(
                id="main-toilets",
                type="toilet",
                level="0",
                label="Restrooms",
                points=_rect(40, 620, 120, 100),
            ),
            IndoorFeature(
                id="corridor-n",
                type="corridor",
                level="0",
                label="North Corridor",
                points=[[200, 180], [800, 180], [800, 200], [200, 200], [200, 180]],
            ),
            IndoorFeature(
                id="corridor-s",
                type="corridor",
                level="0",
                label="South Corridor",
                points=[[200, 600], [800, 600], [800, 620], [200, 620], [200, 600]],
            ),
        ]
    )

    # Level 1 — Departures / gates (aligned with IST_DEMO_GATES)
    gate_layout: dict[str, tuple[float, float]] = {
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
    for gate in IST_DEMO_GATES:
        gx, gy = gate_layout[gate]
        gate_num = gate[1:]
        features.append(
            IndoorFeature(
                id=f"gate-g{gate_num.lower()}",
                type="gate",
                level="1",
                label=gate,
                points=_rect(gx, gy, 120, 80),
            )
        )
    features.extend(
        [
            IndoorFeature(
                id="departures-hall",
                type="hall",
                level="1",
                label="Departures Hall",
                points=_rect(80, 80, 840, 80),
            ),
            IndoorFeature(
                id="departures-spine",
                type="corridor",
                level="1",
                label="Gate Spine",
                points=[[100, 320], [900, 320], [900, 360], [100, 360], [100, 320]],
            ),
            IndoorFeature(
                id="security",
                type="room",
                level="1",
                label="Security",
                points=_rect(380, 80, 240, 100),
            ),
        ]
    )

    return features


def _build_pois() -> list[IndoorPointOfInterest]:
    return [
        IndoorPointOfInterest(
            id="poi-you-0",
            type="you",
            level="0",
            label="You",
            x=500,
            y=400,
        ),
        IndoorPointOfInterest(
            id="poi-duty-free",
            type="shop",
            level="0",
            label="Duty Free",
            x=890,
            y=400,
        ),
        IndoorPointOfInterest(
            id="poi-food-main",
            type="food",
            level="0",
            label="Food Court",
            x=110,
            y=400,
        ),
        # Level 1 — departures amenities near gate spine (for highlight demos)
        IndoorPointOfInterest(
            id="poi-coffee-spine",
            type="coffee",
            level="1",
            label="Coffee Point",
            x=420,
            y=280,
        ),
        IndoorPointOfInterest(
            id="poi-coffee-g12",
            type="coffee",
            level="1",
            label="Starbucks Gate Area",
            x=760,
            y=400,
        ),
        IndoorPointOfInterest(
            id="poi-coffee-g6",
            type="coffee",
            level="1",
            label="Cafe G6",
            x=300,
            y=420,
        ),
        IndoorPointOfInterest(
            id="poi-bites-spine",
            type="quick_bites",
            level="1",
            label="Quick Bites",
            x=500,
            y=280,
        ),
        IndoorPointOfInterest(
            id="poi-bites-g12",
            type="food",
            level="1",
            label="Grab & Go G12",
            x=700,
            y=420,
        ),
        IndoorPointOfInterest(
            id="poi-bites-g4",
            type="food",
            level="1",
            label="Snack Bar G4",
            x=680,
            y=240,
        ),
        IndoorPointOfInterest(
            id="poi-g12",
            type="gate",
            level="1",
            label="G12",
            x=880,
            y=520,
        ),
        IndoorPointOfInterest(
            id="poi-g6",
            type="gate",
            level="1",
            label="G6",
            x=380,
            y=520,
        ),
    ]


def build_istanbul_indoor_map(*, highlight_gate: str | None = None) -> IndoorMapResponse:
    """Return a reliable curated indoor map for IST graduation demo."""
    from app.services.istanbul_indoor_geo import enrich_indoor_map

    base = IndoorMapResponse(
        airport_iata=IST_IATA,
        airport_name=IST_NAME,
        default_level="0",
        levels=_LEVELS,
        bounds=IndoorMapBounds(),
        features=_build_features(),
        pois=_build_pois(),
        source="fallback",
        is_fallback=True,
        supported=True,
        message="Curated Istanbul Airport indoor layout for demo.",
        highlight_gate=highlight_gate,
    )
    return enrich_indoor_map(base, gate=highlight_gate)
