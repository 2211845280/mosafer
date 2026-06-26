import 'package:flutter/material.dart';

import 'indoor_route_builder.dart';
import '../../../../core/theme/app_theme_extension.dart';

/// Draws a route polyline in the same 0–1000 coordinate space as [IndoorMapPainter].
class IndoorRoutePainter extends CustomPainter {
  const IndoorRoutePainter({
    required this.routePoints,
    this.progress = 1,
    this.mapSize = indoorMapCoordinateSize,
  });

  final List<Offset> routePoints;
  final double progress;
  final double mapSize;

  static const Color routeColor = Color(0xFF4A91F8);
  static const Color routeShadow = Color(0xAA061326);
  static const Color startColor = Color(0xFF2CE59B);
  static const Color endColor = Color(0xFFFF8B6E);

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.length < 2) {
      return;
    }

    final scaleX = size.width / mapSize;
    final scaleY = size.height / mapSize;
    final scaled = routePoints
        .map((p) => Offset(p.dx * scaleX, p.dy * scaleY))
        .toList();

    final path = Path()..moveTo(scaled.first.dx, scaled.first.dy);
    for (final point in scaled.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = routeShadow
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 12,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = routeColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 7,
    );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) {
      return;
    }
    final metric = metrics.first;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final tangent = metric.getTangentForOffset(metric.length * clampedProgress);
    final dot = tangent?.position ?? scaled.last;

    canvas.drawCircle(dot, 10, Paint()..color = routeShadow);
    canvas.drawCircle(dot, 7, Paint()..color = endColor);

    _drawEndpoint(canvas, scaled.first, startColor, 7);
    _drawEndpoint(canvas, scaled.last, endColor, 9);
  }

  void _drawEndpoint(Canvas canvas, Offset point, Color color, double radius) {
    canvas.drawCircle(point, radius + 3, Paint()..color = routeShadow);
    canvas.drawCircle(point, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant IndoorRoutePainter oldDelegate) {
    return oldDelegate.routePoints != routePoints ||
        oldDelegate.progress != progress;
  }
}
