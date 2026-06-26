import 'package:flutter/material.dart';

import '../../../../core/models/flight_weather.dart';
import '../../../../core/utils/weather_formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme_extension.dart';

class FlightWeatherSection extends StatelessWidget {
  final AppLocalizations l10n;
  final FlightWeatherForecast? originWeather;
  final FlightWeatherForecast? destinationWeather;
  final String originLabel;
  final String destinationLabel;
  final int? weatherBufferMinutes;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBackground;

  const FlightWeatherSection({
    super.key,
    required this.l10n,
    required this.originWeather,
    required this.destinationWeather,
    required this.originLabel,
    required this.destinationLabel,
    this.weatherBufferMinutes,
    this.cardColor = const Color(0xFF101F36),
    this.titleColor = const Color(0xFFD5E4FF),
    this.mutedColor = const Color(0xFF6D7D95),
    this.iconBackground = const Color(0xFF1D2D46),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (originWeather == null && destinationWeather == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.flightWeatherTitle,
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          if (originWeather != null)
            _WeatherRow(
              l10n: l10n,
              label: l10n.flightWeatherDepartureDay(originLabel),
              weather: originWeather!,
              titleColor: titleColor,
              mutedColor: mutedColor,
              iconBackground: iconBackground,
            ),
          if (originWeather != null && destinationWeather != null)
            const SizedBox(height: 14),
          if (destinationWeather != null)
            _WeatherRow(
              l10n: l10n,
              label: l10n.flightWeatherArrivalDay(destinationLabel),
              weather: destinationWeather!,
              titleColor: titleColor,
              mutedColor: mutedColor,
              iconBackground: iconBackground,
            ),
          if (weatherBufferMinutes != null && weatherBufferMinutes! > 0) ...[
            const SizedBox(height: 14),
            Text(
              l10n.flightWeatherBufferAdded(weatherBufferMinutes!),
              style: TextStyle(
                color: mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeatherRow extends StatelessWidget {
  final AppLocalizations l10n;
  final String label;
  final FlightWeatherForecast weather;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBackground;

  const _WeatherRow({
    required this.l10n,
    required this.label,
    required this.weather,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final description = weather.description.trim().isEmpty
        ? weatherConditionLabel(l10n, weather.condition)
        : weather.description;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            weatherConditionIcon(weather.condition),
            color: weatherConditionColor(weather.condition),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${weather.temperatureC.round()}°C · ${weatherConditionLabel(l10n, weather.condition)}',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
