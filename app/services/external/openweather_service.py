"""OpenWeatherMap forecast client with mock fallback."""

from __future__ import annotations

from datetime import UTC, datetime

import httpx
import structlog

from app.core.config import settings
from app.schemas.departure_plan import WeatherCondition, WeatherResult
from app.services.external.mock_weather_service import MockWeatherService

logger = structlog.get_logger(__name__)

_FORECAST_URL = "https://api.openweathermap.org/data/2.5/forecast"
_mock = MockWeatherService()


def _map_openweather_main(main: str) -> WeatherCondition:
    normalized = main.strip().lower()
    if normalized in {"clear"}:
        return WeatherCondition.clear
    if normalized in {"clouds", "mist", "fog", "haze", "smoke", "dust"}:
        return WeatherCondition.cloudy
    if normalized in {"rain", "drizzle"}:
        return WeatherCondition.rain
    if normalized in {"snow"}:
        return WeatherCondition.snow
    if normalized in {"thunderstorm", "squall", "tornado"}:
        return WeatherCondition.storm
    return WeatherCondition.cloudy


class OpenWeatherService:
    """Fetch destination weather from OpenWeatherMap."""

    async def get_weather(
        self,
        lat: float,
        lng: float,
        target_time: datetime,
    ) -> WeatherResult:
        if not settings.WEATHER_API_KEY:
            logger.info("openweather.no_api_key, using mock")
            return await _mock.get_weather(lat, lng, target_time)

        params = {
            "lat": lat,
            "lon": lng,
            "appid": settings.WEATHER_API_KEY,
            "units": "metric",
        }
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                response = await client.get(_FORECAST_URL, params=params)
                response.raise_for_status()
                payload = response.json()
        except Exception:
            logger.exception("openweather.fetch_failed, using mock")
            return await _mock.get_weather(lat, lng, target_time)

        entries = payload.get("list")
        if not isinstance(entries, list) or not entries:
            logger.warning("openweather.empty_forecast, using mock")
            return await _mock.get_weather(lat, lng, target_time)

        target_ts = target_time.astimezone(UTC).timestamp()
        best = min(
            entries,
            key=lambda item: abs(
                datetime.fromtimestamp(item["dt"], tz=UTC).timestamp() - target_ts
            ),
        )
        main_block = best.get("main") or {}
        weather_block = (best.get("weather") or [{}])[0]
        condition = _map_openweather_main(str(weather_block.get("main", "Clouds")))
        temperature_c = round(float(main_block.get("temp", 20.0)), 1)

        return WeatherResult(
            condition=condition,
            temperature_c=temperature_c,
            visibility_km=10.0,
            severe_alert=condition == WeatherCondition.storm,
            description=str(weather_block.get("description", "")),
        )


_openweather: OpenWeatherService | None = None


async def get_destination_weather(
    lat: float,
    lng: float,
    target_time: datetime,
) -> WeatherResult:
    """Return weather for a destination, preferring OpenWeather when configured."""
    global _openweather
    if _openweather is None:
        _openweather = OpenWeatherService()
    return await _openweather.get_weather(lat, lng, target_time)
