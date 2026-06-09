"""Seed data for airports matching mock flight routes.

Covers the 10 airports used in mock flight data with realistic
lat/lng, terminal info, amenities, and map URLs.
"""

from __future__ import annotations

from app.services.istanbul_gate_data import IST_DEMO_GATES

AIRPORT_SEEDS: list[dict] = [
    {
        "iata_code": "MJI",
        "name": "Mitiga International Airport",
        "city": "Tripoli",
        "country": "Libya",
        "timezone": "Africa/Tripoli",
        "latitude": 32.8941,
        "longitude": 13.2760,
        "terminal_info": {
            "terminals": ["Main Terminal"],
            "gates": {"Main Terminal": [f"G{i}" for i in range(1, 15)]},
        },
        "amenities": {
            "food": ["Cafe", "Snack Bar"],
            "shops": ["Duty Free"],
            "lounges": [],
        },
        "map_url": None,
    },
    {
        "iata_code": "AMM",
        "name": "Queen Alia International Airport",
        "city": "Amman",
        "country": "Jordan",
        "timezone": "Asia/Amman",
        "latitude": 31.7226,
        "longitude": 35.9932,
        "terminal_info": {
            "terminals": ["Main Terminal"],
            "gates": {"Main Terminal": [f"G{i}" for i in range(1, 25)]},
        },
        "amenities": {
            "food": ["Gloria Jean's Coffees", "Popeyes", "Burger King"],
            "shops": ["Duty Free", "Jordan River Foundation"],
            "lounges": ["Crown Lounge", "Petra Lounge"],
        },
        "map_url": "https://www.qaiairport.com/en/map",
    },
    {
        "iata_code": "DXB",
        "name": "Dubai International Airport",
        "city": "Dubai",
        "country": "United Arab Emirates",
        "timezone": "Asia/Dubai",
        "latitude": 25.2532,
        "longitude": 55.3657,
        "terminal_info": {
            "terminals": ["T1", "T2", "T3"],
            "gates": {
                "T1": [f"D{i}" for i in range(1, 50)],
                "T3": [f"A{i}" for i in range(1, 30)] + [f"B{i}" for i in range(1, 40)],
            },
        },
        "amenities": {
            "food": ["Shake Shack", "McDonald's", "Costa Coffee", "Paul"],
            "shops": ["Dubai Duty Free", "Hermès", "Chanel"],
            "lounges": ["Emirates First Class Lounge", "Marhaba Lounge", "Al Majlis Lounge"],
        },
        "map_url": "https://www.dubaiairports.ae/map",
    },
    {
        "iata_code": "IST",
        "name": "Istanbul Airport",
        "city": "Istanbul",
        "country": "Turkey",
        "timezone": "Europe/Istanbul",
        "latitude": 41.2753,
        "longitude": 28.7519,
        "terminal_info": {
            "terminals": ["Main Terminal"],
            "gates": {"Main Terminal": list(IST_DEMO_GATES)},
        },
        "amenities": {
            "food": ["Starbucks", "Burger King", "Turkish Kitchen"],
            "shops": ["Duty Free Shops", "Vakko", "Koton"],
            "lounges": ["Turkish Airlines Lounge", "IGA Lounge"],
        },
        "map_url": "https://www.istairport.com/en/map",
    },
    {
        "iata_code": "CAI",
        "name": "Cairo International Airport",
        "city": "Cairo",
        "country": "Egypt",
        "timezone": "Africa/Cairo",
        "latitude": 30.1219,
        "longitude": 31.4056,
        "terminal_info": {
            "terminals": ["T1", "T2", "T3"],
            "gates": {
                "T2": [f"C{i}" for i in range(1, 20)],
                "T3": [f"D{i}" for i in range(1, 15)],
            },
        },
        "amenities": {
            "food": ["Costa Coffee", "McDonald's"],
            "shops": ["Egypt Duty Free"],
            "lounges": ["EgyptAir Star Alliance Lounge"],
        },
        "map_url": "https://www.cairo-airport.com/en/map",
    },
    {
        "iata_code": "JED",
        "name": "King Abdulaziz International Airport",
        "city": "Jeddah",
        "country": "Saudi Arabia",
        "timezone": "Asia/Riyadh",
        "latitude": 21.6796,
        "longitude": 39.1565,
        "terminal_info": {
            "terminals": ["T1"],
            "gates": {"T1": [f"A{i}" for i in range(1, 40)]},
        },
        "amenities": {
            "food": ["Starbucks", "Dunkin'", "Al Baik"],
            "shops": ["Duty Free", "Al Raha"],
            "lounges": ["Al Fursan Lounge", "Wellcome Lounge"],
        },
        "map_url": "https://www.kaia.sa/en/map",
    },
    {
        "iata_code": "LHR",
        "name": "London Heathrow Airport",
        "city": "London",
        "country": "United Kingdom",
        "timezone": "Europe/London",
        "latitude": 51.4700,
        "longitude": -0.4543,
        "terminal_info": {
            "terminals": ["T2", "T3", "T4", "T5"],
            "gates": {
                "T2": [f"B{i}" for i in range(1, 30)],
                "T5": [f"A{i}" for i in range(1, 25)] + [f"B{i}" for i in range(1, 20)],
            },
        },
        "amenities": {
            "food": ["Gordon Ramsay Plane Food", "Wagamama", "Pret A Manger"],
            "shops": ["Harrods", "World Duty Free", "Boots"],
            "lounges": ["British Airways Galleries", "Plaza Premium Lounge"],
        },
        "map_url": "https://www.heathrow.com/at-the-airport/terminal-maps",
    },
    {
        "iata_code": "JFK",
        "name": "John F. Kennedy International Airport",
        "city": "New York",
        "country": "United States",
        "timezone": "America/New_York",
        "latitude": 40.6413,
        "longitude": -73.7781,
        "terminal_info": {
            "terminals": ["T1", "T4", "T5", "T7", "T8"],
            "gates": {
                "T1": [f"B{i}" for i in range(1, 20)],
                "T4": [f"A{i}" for i in range(1, 15)] + [f"B{i}" for i in range(20, 40)],
            },
        },
        "amenities": {
            "food": ["Shake Shack", "Sushi Nakazawa", "Blue Smoke"],
            "shops": ["Duty Free Americas", "Hudson News", "InMotion"],
            "lounges": ["TWA Hotel", "Centurion Lounge", "Delta SkyClub"],
        },
        "map_url": "https://www.jfkairport.com/at-airport/airport-maps",
    },
    {
        "iata_code": "RUH",
        "name": "King Khalid International Airport",
        "city": "Riyadh",
        "country": "Saudi Arabia",
        "timezone": "Asia/Riyadh",
        "latitude": 24.9576,
        "longitude": 46.6988,
        "terminal_info": {
            "terminals": ["T1", "T2", "T5"],
            "gates": {
                "T1": [f"A{i}" for i in range(1, 20)],
                "T5": [f"E{i}" for i in range(1, 30)],
            },
        },
        "amenities": {
            "food": ["Starbucks", "Dunkin'", "Kudu"],
            "shops": ["Duty Free", "Saudia Gift Shop"],
            "lounges": ["Al Fursan Lounge", "NaSmiles Lounge"],
        },
        "map_url": "https://www.riyadhairports.com/en/map",
    },
    {
        "iata_code": "CDG",
        "name": "Charles de Gaulle Airport",
        "city": "Paris",
        "country": "France",
        "timezone": "Europe/Paris",
        "latitude": 49.0097,
        "longitude": 2.5479,
        "terminal_info": {
            "terminals": ["T1", "T2A", "T2C", "T2D", "T2E", "T2F", "T3"],
            "gates": {
                "T1": [f"S{i}" for i in range(10, 50)],
                "T2E": [f"K{i}" for i in range(20, 60)] + [f"L{i}" for i in range(20, 60)],
            },
        },
        "amenities": {
            "food": ["Ladurée", "Paul", "McDonald's", "Café Maxim's"],
            "shops": ["Buy Paris Duty Free", "Hermès", "Longchamp"],
            "lounges": ["Air France Lounge", "Star Alliance Lounge", "Yotel"],
        },
        "map_url": "https://www.parisaeroport.fr/en/maps",
    },
    {
        "iata_code": "FRA",
        "name": "Frankfurt Airport",
        "city": "Frankfurt",
        "country": "Germany",
        "timezone": "Europe/Berlin",
        "latitude": 50.0379,
        "longitude": 8.5622,
        "terminal_info": {
            "terminals": ["T1", "T2"],
            "gates": {
                "T1": [f"A{i}" for i in range(1, 30)] + [f"B{i}" for i in range(1, 50)] + [f"Z{i}" for i in range(1, 60)],
                "T2": [f"D{i}" for i in range(1, 20)] + [f"E{i}" for i in range(1, 20)],
            },
        },
        "amenities": {
            "food": ["Paulaner", "McDonald's", "Starbucks", "Rewe To Go"],
            "shops": ["Heinemann Duty Free", "Hugo Boss", "Rimowa"],
            "lounges": ["Lufthansa Senator Lounge", "Lufthansa First Class Terminal", "Primeclass Lounge"],
        },
        "map_url": "https://www.frankfurt-airport.com/en/flights-and-transfer/airport-map.html",
    },
    {
        "iata_code": "BKK",
        "name": "Suvarnabhumi Airport",
        "city": "Bangkok",
        "country": "Thailand",
        "timezone": "Asia/Bangkok",
        "latitude": 13.6900,
        "longitude": 100.7501,
        "terminal_info": {
            "terminals": ["Main Terminal"],
            "gates": {"Main Terminal": [f"G{i}" for i in range(1, 60)]},
        },
        "amenities": {
            "food": ["Starbucks", "McDonald's", "Pret A Manger"],
            "shops": ["King Power Duty Free", "Hermès"],
            "lounges": ["Royal Silk Lounge", "Miracle Lounge"],
        },
        "map_url": "https://www.bangkokairportonline.com/map",
    },
    {
        "iata_code": "SIN",
        "name": "Changi Airport",
        "city": "Singapore",
        "country": "Singapore",
        "timezone": "Asia/Singapore",
        "latitude": 1.3644,
        "longitude": 103.9915,
        "terminal_info": {
            "terminals": ["T1", "T2", "T3", "T4"],
            "gates": {
                "T1": [f"C{i}" for i in range(1, 40)],
                "T3": [f"A{i}" for i in range(1, 30)],
            },
        },
        "amenities": {
            "food": ["Killiney Kopitiam", "Burger King", "Toast Box"],
            "shops": ["Changi Recommends", "Duty Free"],
            "lounges": ["KrisFlyer Gold Lounge", "Plaza Premium Lounge"],
        },
        "map_url": "https://www.changiairport.com/en/at-changi/map.html",
    },
    {
        "iata_code": "KUL",
        "name": "Kuala Lumpur International Airport",
        "city": "Kuala Lumpur",
        "country": "Malaysia",
        "timezone": "Asia/Kuala_Lumpur",
        "latitude": 2.7456,
        "longitude": 101.7072,
        "terminal_info": {
            "terminals": ["KLIA", "KLIA2"],
            "gates": {
                "KLIA": [f"C{i}" for i in range(1, 40)],
                "KLIA2": [f"J{i}" for i in range(1, 30)],
            },
        },
        "amenities": {
            "food": ["OldTown White Coffee", "McDonald's"],
            "shops": ["Eraman Duty Free", "Harrods"],
            "lounges": ["Golden Lounge", "Plaza Premium Lounge"],
        },
        "map_url": "https://www.klia.com.my/en/map",
    },
    {
        "iata_code": "CGK",
        "name": "Soekarno-Hatta International Airport",
        "city": "Jakarta",
        "country": "Indonesia",
        "timezone": "Asia/Jakarta",
        "latitude": -6.1256,
        "longitude": 106.6559,
        "terminal_info": {
            "terminals": ["T1", "T2", "T3"],
            "gates": {
                "T3": [f"D{i}" for i in range(1, 30)],
            },
        },
        "amenities": {
            "food": ["Starbucks", "Burger King"],
            "shops": ["Duty Free", "Planet Sport"],
            "lounges": ["Garuda Indonesia Lounge", "Pearl Lounge"],
        },
        "map_url": None,
    },
    {
        "iata_code": "MNL",
        "name": "Ninoy Aquino International Airport",
        "city": "Manila",
        "country": "Philippines",
        "timezone": "Asia/Manila",
        "latitude": 14.5086,
        "longitude": 121.0198,
        "terminal_info": {
            "terminals": ["T1", "T2", "T3"],
            "gates": {
                "T3": [f"G{i}" for i in range(100, 130)],
            },
        },
        "amenities": {
            "food": ["Jollibee", "Starbucks"],
            "shops": ["Duty Free Philippines"],
            "lounges": ["Mabuhay Lounge", "PAGSS Lounge"],
        },
        "map_url": None,
    },
    {
        "iata_code": "HAN",
        "name": "Noi Bai International Airport",
        "city": "Hanoi",
        "country": "Vietnam",
        "timezone": "Asia/Ho_Chi_Minh",
        "latitude": 21.2212,
        "longitude": 105.8072,
        "terminal_info": {
            "terminals": ["T1", "T2"],
            "gates": {
                "T2": [f"A{i}" for i in range(1, 25)],
            },
        },
        "amenities": {
            "food": ["Highlands Coffee", "Lotteria"],
            "shops": ["Duty Free", "Lotte Duty Free"],
            "lounges": ["Lotus Lounge", "CIP Lounge"],
        },
        "map_url": None,
    },
    {
        "iata_code": "SGN",
        "name": "Tan Son Nhat International Airport",
        "city": "Ho Chi Minh City",
        "country": "Vietnam",
        "timezone": "Asia/Ho_Chi_Minh",
        "latitude": 10.8188,
        "longitude": 106.6520,
        "terminal_info": {
            "terminals": ["T1", "T2", "T3"],
            "gates": {
                "T2": [f"D{i}" for i in range(1, 20)],
            },
        },
        "amenities": {
            "food": ["Pho 24", "Starbucks"],
            "shops": ["Saigon Duty Free"],
            "lounges": ["Le Saigonnais Lounge", "CIP Lounge"],
        },
        "map_url": None,
    },
    {
        "iata_code": "DPS",
        "name": "Ngurah Rai International Airport",
        "city": "Bali",
        "country": "Indonesia",
        "timezone": "Asia/Makassar",
        "latitude": -8.7482,
        "longitude": 115.1672,
        "terminal_info": {
            "terminals": ["International Terminal"],
            "gates": {"International Terminal": [f"G{i}" for i in range(1, 20)]},
        },
        "amenities": {
            "food": ["Starbucks", "Hard Rock Cafe"],
            "shops": ["Duty Free", "DFS"],
            "lounges": ["Premier Lounge", "JAS Lounge"],
        },
        "map_url": None,
    },
    {
        "iata_code": "PNH",
        "name": "Phnom Penh International Airport",
        "city": "Phnom Penh",
        "country": "Cambodia",
        "timezone": "Asia/Phnom_Penh",
        "latitude": 11.5466,
        "longitude": 104.8440,
        "terminal_info": {
            "terminals": ["International Terminal"],
            "gates": {"International Terminal": [f"G{i}" for i in range(1, 15)]},
        },
        "amenities": {
            "food": ["Coffee Corner", "Burger King"],
            "shops": ["Duty Free"],
            "lounges": ["CIP Lounge"],
        },
        "map_url": None,
    },
]
