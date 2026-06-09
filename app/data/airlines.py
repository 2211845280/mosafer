"""IATA airline codes → display names and e-ticket numeric prefixes."""

from __future__ import annotations

# code → (full name, e-ticket numeric prefix used on real tickets)
CARRIERS: dict[str, tuple[str, str]] = {
    "MS": ("EgyptAir", "077"),
    "LN": ("Libyan Airlines", "148"),
    "TK": ("Turkish Airlines", "235"),
    "PC": ("Pegasus Airlines", "624"),
    "EK": ("Emirates", "176"),
    "FZ": ("flydubai", "141"),
    "RJ": ("Royal Jordanian", "512"),
    "SV": ("Saudia", "065"),
    "QR": ("Qatar Airways", "157"),
    "TU": ("Tunisair", "199"),
    "BA": ("British Airways", "125"),
    "AF": ("Air France", "057"),
    "AZ": ("ITA Airways", "055"),
    "IB": ("Iberia", "075"),
    "LH": ("Lufthansa", "220"),
    "KL": ("KLM Royal Dutch Airlines", "074"),
    "ET": ("Ethiopian Airlines", "071"),
    "GF": ("Gulf Air", "072"),
    "WY": ("Oman Air", "910"),
    "XY": ("flynas", "593"),
    "G9": ("Air Arabia", "514"),
    "ME": ("Middle East Airlines", "076"),
    "AT": ("Royal Air Maroc", "147"),
    "AH": ("Air Algérie", "124"),
    "UL": ("SriLankan Airlines", "603"),
    "EY": ("Etihad Airways", "607"),
    "XQ": ("SunExpress", "564"),
}

CABIN_CLASSES = ("Economy", "Premium Economy", "Business")


def carrier_name(code: str) -> str:
    key = code.strip().upper()
    return CARRIERS.get(key, (f"Airline {key}", "999"))[0]


def carrier_numeric(code: str) -> str:
    key = code.strip().upper()
    return CARRIERS.get(key, (f"Airline {key}", "999"))[1]
