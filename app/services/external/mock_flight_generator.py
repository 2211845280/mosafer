"""Programmatic mock flight catalogue builder.

Generates repeatable demo offers (deterministic prices) for Mitiga (MJI)
and other hub routes used in flight search.
"""

from __future__ import annotations

from decimal import Decimal

# Departure times in catalogue are templates only; search assigns per-day random times.
_DEPARTURE_SLOTS: tuple[str, ...] = (
    "06:00",
    "07:45",
    "09:30",
    "11:15",
    "13:00",
    "14:45",
    "16:30",
    "18:15",
    "20:00",
    "21:45",
)

# (iata, city, country, duration_hours, price_min_usd, price_max_usd, carriers)
MJI_OUTBOUND_ROUTES: tuple[tuple[str, str, str, float, int, int, tuple[str, ...]], ...] = (
    ("CAI", "Cairo", "Egypt", 2.0, 95, 215, ("MS", "LN")),
    ("IST", "Istanbul", "Turkey", 3.5, 155, 345, ("TK", "PC")),
    ("DXB", "Dubai", "United Arab Emirates", 4.5, 210, 480, ("EK", "FZ")),
    ("AMM", "Amman", "Jordan", 3.0, 140, 310, ("RJ", "LN")),
    ("JED", "Jeddah", "Saudi Arabia", 3.5, 175, 390, ("SV", "MS")),
    ("RUH", "Riyadh", "Saudi Arabia", 4.0, 190, 420, ("SV", "RJ")),
    ("DOH", "Doha", "Qatar", 4.5, 220, 495, ("QR", "MS")),
    ("TUN", "Tunis", "Tunisia", 1.5, 85, 195, ("TU", "LN")),
    ("LHR", "London", "United Kingdom", 5.5, 380, 720, ("BA", "MS")),
    ("CDG", "Paris", "France", 5.0, 350, 680, ("AF", "MS")),
    ("FCO", "Rome", "Italy", 4.5, 320, 620, ("AZ", "MS")),
    ("MAD", "Madrid", "Spain", 5.0, 340, 650, ("IB", "MS")),
    ("FRA", "Frankfurt", "Germany", 4.5, 360, 690, ("LH", "TK")),
    ("BCN", "Barcelona", "Spain", 4.5, 330, 640, ("IB", "PC")),
    ("MUC", "Munich", "Germany", 4.5, 355, 680, ("LH", "MS")),
    ("ADD", "Addis Ababa", "Ethiopia", 5.0, 280, 520, ("ET", "MS")),
)

# Presentation reference — origin hub for demo searches.
MJI_ORIGIN = {
    "iata": "MJI",
    "name": "Mitiga International Airport",
    "city": "Tripoli",
    "country": "Libya",
}

# (iata, city, country, duration_hours, price_min_usd, price_max_usd, carriers)
IST_OUTBOUND_ROUTES: tuple[tuple[str, str, str, float, int, int, tuple[str, ...]], ...] = (
    ("CAI", "Cairo", "Egypt", 2.5, 120, 280, ("TK", "MS")),
    ("AMM", "Amman", "Jordan", 2.5, 130, 290, ("TK", "RJ")),
    ("DXB", "Dubai", "United Arab Emirates", 4.5, 200, 450, ("TK", "EK")),
    ("JED", "Jeddah", "Saudi Arabia", 3.5, 175, 390, ("TK", "SV")),
    ("RUH", "Riyadh", "Saudi Arabia", 3.5, 180, 400, ("TK", "SV")),
    ("LHR", "London", "United Kingdom", 4.5, 320, 720, ("TK", "BA")),
    ("CDG", "Paris", "France", 4.0, 300, 680, ("TK", "AF")),
    ("FRA", "Frankfurt", "Germany", 3.5, 290, 650, ("TK", "LH")),
    ("JFK", "New York", "United States", 11.0, 520, 980, ("TK", "TK")),
    ("BKK", "Bangkok", "Thailand", 9.0, 380, 820, ("TK", "TG")),
    ("SIN", "Singapore", "Singapore", 11.0, 420, 900, ("TK", "SQ")),
    ("KUL", "Kuala Lumpur", "Malaysia", 10.0, 360, 780, ("TK", "MH")),
    ("CGK", "Jakarta", "Indonesia", 11.5, 400, 850, ("TK", "GA")),
    ("MNL", "Manila", "Philippines", 12.0, 410, 880, ("TK", "PR")),
    ("HAN", "Hanoi", "Vietnam", 10.0, 390, 840, ("TK", "VN")),
    ("SGN", "Ho Chi Minh City", "Vietnam", 10.5, 395, 850, ("TK", "VN")),
    ("DPS", "Bali", "Indonesia", 12.0, 430, 920, ("TK", "GA")),
    ("PNH", "Phnom Penh", "Cambodia", 10.5, 385, 830, ("TK", "VN")),
)

IST_ORIGIN = {
    "iata": "IST",
    "name": "Istanbul Airport",
    "city": "Istanbul",
    "country": "Turkey",
}


def _price_for_slot(slot_index: int, price_min: int, price_max: int, carrier_idx: int) -> str:
    """Deterministic price spread across the 10 daily departures."""
    span = price_max - price_min
    base = price_min + (slot_index * span) // max(len(_DEPARTURE_SLOTS) - 1, 1)
    # Small carrier-based offset keeps same-slot prices distinct when carriers rotate.
    offset = (carrier_idx * 7) % 25
    price = min(price_max, base + offset)
    return f"{Decimal(price):.2f}"


def _flight_number(carrier: str, dest_iata: str, slot_index: int) -> str:
    base = 100 + slot_index * 17 + sum(ord(c) for c in dest_iata) % 50
    return f"{carrier}{base}"


def build_mji_outbound_flights() -> list[dict]:
    """Build 10 offers per MJI destination (120 flights by default)."""
    flights: list[dict] = []
    for dest_iata, _city, _country, duration, pmin, pmax, carriers in MJI_OUTBOUND_ROUTES:
        for slot_index, dep_time in enumerate(_DEPARTURE_SLOTS):
            carrier = carriers[slot_index % len(carriers)]
            seq = slot_index + 1
            offer_id = f"MOCK-MJI-{dest_iata}-{seq:03d}"
            flights.append(
                {
                    "offer_id": offer_id,
                    "provider_flight_id": f"{carrier}-MJI-{dest_iata}-{dep_time.replace(':', '')}",
                    "origin_iata": "MJI",
                    "destination_iata": dest_iata,
                    "carrier_code": carrier,
                    "flight_number": _flight_number(carrier, dest_iata, slot_index),
                    "departure_time": dep_time,
                    "arrival_time": dep_time,
                    "duration_hours": duration,
                    "total_price": _price_for_slot(
                        slot_index,
                        pmin,
                        pmax,
                        slot_index % len(carriers),
                    ),
                    "currency": "USD",
                },
            )
    return flights


def build_ist_outbound_flights() -> list[dict]:
    """Build demo offers from Istanbul Airport to international destinations."""
    flights: list[dict] = []
    for dest_iata, _city, _country, duration, pmin, pmax, carriers in IST_OUTBOUND_ROUTES:
        for slot_index, dep_time in enumerate(_DEPARTURE_SLOTS):
            carrier = carriers[slot_index % len(carriers)]
            seq = slot_index + 1
            offer_id = f"MOCK-IST-{dest_iata}-{seq:03d}"
            flights.append(
                {
                    "offer_id": offer_id,
                    "provider_flight_id": f"{carrier}-IST-{dest_iata}-{dep_time.replace(':', '')}",
                    "origin_iata": "IST",
                    "destination_iata": dest_iata,
                    "carrier_code": carrier,
                    "flight_number": _flight_number(carrier, dest_iata, slot_index),
                    "departure_time": dep_time,
                    "arrival_time": dep_time,
                    "duration_hours": duration,
                    "total_price": _price_for_slot(
                        slot_index,
                        pmin,
                        pmax,
                        slot_index % len(carriers),
                    ),
                    "currency": "USD",
                },
            )
    return flights


def presentation_destinations() -> list[dict[str, str]]:
    """Countries/cities served from Mitiga — handy for demos."""
    return [
        {
            "iata": iata,
            "city": city,
            "country": country,
            "sample_route": f"MJI → {iata}",
        }
        for iata, city, country, *_ in MJI_OUTBOUND_ROUTES
    ]
