"""Mock weather service.

Returns deterministic weather based on location hash and date,
with latitude-band temperature variation.
"""

from __future__ import annotations

import hashlib
from datetime import datetime

import structlog

from app.schemas.departure_plan import WeatherCondition, WeatherResult

logger = structlog.get_logger(__name__)

_CONDITIONS = list(WeatherCondition)
_DESCRIPTIONS = {
    WeatherCondition.clear: "Clear skies, good visibility",
    WeatherCondition.cloudy: "Overcast skies",
    WeatherCondition.rain: "Rain expected, roads may be wet",
    WeatherCondition.snow: "Snowfall expected, slippery roads",
    WeatherCondition.storm: "Severe storm warning, travel with caution",
}


def _seed(lat: float, lng: float, date_str: str) -> int:
    raw = f"{round(lat, 2)}:{round(lng, 2)}:{date_str}"
    return int(hashlib.md5(raw.encode()).hexdigest(), 16)


class MockWeatherService:
    """Simulated weather provider seeded by location + date."""

    async def get_weather(
        self,
        lat: float,
        lng: float,
        target_time: datetime,
    ) -> WeatherResult:
        s = _seed(lat, lng, target_time.strftime("%Y-%m-%d"))

        condition = _CONDITIONS[s % len(_CONDITIONS)]

        abs_lat = abs(lat)
        if abs_lat < 23.5:
            base_temp = 30.0
        elif abs_lat < 45.0:
            base_temp = 18.0
        elif abs_lat < 60.0:
            base_temp = 8.0
        else:
            base_temp = -5.0

        temp_offset = (s % 15) - 7
        temperature_c = round(base_temp + temp_offset, 1)

        if condition in (WeatherCondition.rain, WeatherCondition.storm):
            visibility_km = round(2.0 + (s % 50) / 10, 1)
        elif condition == WeatherCondition.snow:
            visibility_km = round(1.0 + (s % 40) / 10, 1)
        else:
            visibility_km = round(8.0 + (s % 30) / 10, 1)

        severe_alert = condition == WeatherCondition.storm and (s % 5 == 0)

        logger.info(
            "mock_weather.get",
            condition=condition.value,
            temperature_c=temperature_c,
            severe_alert=severe_alert,
        )

        return WeatherResult(
            condition=condition,
            temperature_c=temperature_c,
            visibility_km=visibility_km,
            severe_alert=severe_alert,
            description=_DESCRIPTIONS[condition],
        )
