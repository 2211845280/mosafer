import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

String weatherConditionLabel(AppLocalizations l10n, String? condition) {
  switch (condition) {
    case 'clear':
      return l10n.weatherClear;
    case 'rain':
      return l10n.weatherRain;
    case 'snow':
      return l10n.weatherSnow;
    case 'storm':
      return l10n.weatherStorm;
    case 'cloudy':
    default:
      return l10n.weatherCloudy;
  }
}

IconData weatherConditionIcon(String? condition) {
  switch (condition) {
    case 'clear':
      return Icons.wb_sunny_outlined;
    case 'rain':
      return Icons.water_drop_outlined;
    case 'snow':
      return Icons.ac_unit;
    case 'storm':
      return Icons.thunderstorm_outlined;
    case 'cloudy':
    default:
      return Icons.cloud_outlined;
  }
}

Color weatherConditionColor(String? condition) {
  switch (condition) {
    case 'clear':
      return const Color(0xFFFFD54F);
    case 'rain':
      return const Color(0xFF64B5F6);
    case 'snow':
      return const Color(0xFFB3E5FC);
    case 'storm':
      return const Color(0xFFCE93D8);
    case 'cloudy':
    default:
      return const Color(0xFF90A4AE);
  }
}
