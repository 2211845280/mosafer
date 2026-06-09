import 'dart:ui';

import '../../domain/indoor_map.dart';

/// Normalized indoor map coordinate space (matches backend fallback layout).
const double indoorMapCoordinateSize = 1000;

/// Builds a demo walking path along corridors to [gate] on [level].
List<Offset> buildIndoorRoutePath({
  required IndoorMapData map,
  required String level,
  required String gate,
}) {
  final normalizedGate = gate.trim().toUpperCase();
  final end = _gateCenter(map, level, normalizedGate);
  if (end == null) {
    return const [];
  }

  final start = _routeStart(map, level);
  if (level == '1') {
    const spineY = 340.0;
    return [
      start,
      Offset(start.dx, spineY),
      Offset(end.dx, spineY),
      end,
    ];
  }

  if (level == '0') {
    const northCorridorY = 190.0;
    const southCorridorY = 610.0;
    return [
      start,
      Offset(start.dx, northCorridorY),
      Offset(end.dx, northCorridorY),
      Offset(end.dx, southCorridorY),
      end,
    ];
  }

  return [start, end];
}

Offset _routeStart(IndoorMapData map, String level) {
  final you = map.poisForLevel(level).where((p) => p.type == 'you').toList();
  if (you.isNotEmpty) {
    return Offset(you.first.x, you.first.y);
  }

  if (level == '1') {
    final security = map.featuresForLevel(level).where(
      (f) => f.id == 'security' || f.label?.toLowerCase() == 'security',
    );
    if (security.isNotEmpty) {
      return _featureCenter(security.first);
    }
    return const Offset(500, 130);
  }

  return const Offset(500, 400);
}

Offset? _gateCenter(IndoorMapData map, String level, String gate) {
  for (final poi in map.poisForLevel(level)) {
    if (poi.type == 'gate' && poi.label.trim().toUpperCase() == gate) {
      return Offset(poi.x, poi.y);
    }
  }

  for (final feature in map.featuresForLevel(level)) {
    if (feature.type != 'gate') {
      continue;
    }
    final label = feature.label?.trim().toUpperCase();
    if (label == gate) {
      return _featureCenter(feature);
    }
  }

  return null;
}

Offset _featureCenter(IndoorFeature feature) {
  if (feature.points.isEmpty) {
    return Offset.zero;
  }
  var sumX = 0.0;
  var sumY = 0.0;
  for (final point in feature.points) {
    sumX += point[0];
    sumY += point[1];
  }
  final count = feature.points.length;
  return Offset(sumX / count, sumY / count);
}
