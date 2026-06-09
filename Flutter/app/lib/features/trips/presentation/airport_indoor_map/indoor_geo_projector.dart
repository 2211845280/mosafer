import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Projects WGS84 to screen pixels (Web Mercator, Leaflet / OpenLevelUp compatible).
class IndoorGeoProjector {
  const IndoorGeoProjector({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  final double centerLat;
  final double centerLng;
  final int zoom;

  /// Fine-tune overlay vs embedded OpenLevelUp chrome crop.
  final double offsetX;
  final double offsetY;

  static double _worldX(double lng, int zoom) {
    final scale = 256.0 * math.pow(2, zoom).toDouble();
    return (lng + 180) / 360 * scale;
  }

  static double _worldY(double lat, int zoom) {
    final scale = 256.0 * math.pow(2, zoom).toDouble();
    final latRad = lat * math.pi / 180;
    final y = (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2;
    return y * scale;
  }

  Offset project(double lat, double lng, Size viewSize) {
    final cx = _worldX(centerLng, zoom);
    final cy = _worldY(centerLat, zoom);
    final px = _worldX(lng, zoom) - cx;
    final py = _worldY(lat, zoom) - cy;
    return Offset(
      viewSize.width / 2 + px + offsetX,
      viewSize.height / 2 + py + offsetY,
    );
  }
}
