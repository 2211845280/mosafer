import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Human-readable traffic label from API `traffic_level` (`low` / `moderate` / `heavy`).
String trafficLevelLabel(AppLocalizations l10n, String? level) {
  switch (level) {
    case 'heavy':
      return l10n.trafficHeavy;
    case 'moderate':
      return l10n.trafficModerate;
    case 'low':
    default:
      return l10n.trafficLow;
  }
}

Color trafficLevelColor(String? level) {
  switch (level) {
    case 'heavy':
      return const Color(0xFFE57373);
    case 'moderate':
      return const Color(0xFFFFB74D);
    case 'low':
    default:
      return const Color(0xFF81C784);
  }
}

String formatDistanceKm(AppLocalizations l10n, num? km) {
  if (km == null) return '-- km';
  return l10n.planDepartureDistanceValue(km.toStringAsFixed(1));
}

String formatExpectedArrival(String? leaveAtIso, num? travelMinutes) {
  final leaveAt = DateTime.tryParse(leaveAtIso ?? '');
  if (leaveAt == null || travelMinutes == null) {
    return '--:--';
  }
  final arrival = leaveAt.add(Duration(minutes: travelMinutes.round()));
  final hour = arrival.hour.toString().padLeft(2, '0');
  final minute = arrival.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
