import 'package:flutter/material.dart';

import '../../domain/indoor_map.dart';
import '../../../../core/theme/app_theme_extension.dart';

class IndoorMapPainter extends CustomPainter {
  final List<IndoorFeature> features;
  final List<IndoorPoi> pois;
  final String? highlightGate;

  IndoorMapPainter({
    required this.features,
    required this.pois,
    this.highlightGate,
  });

  static const double _mapSize = 1000;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _mapSize;
    final scaleY = size.height / _mapSize;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF07172D),
    );

    _drawGrid(canvas, size);

    for (final feature in features) {
      if (feature.points.length < 2) continue;
      final path = Path();
      for (var i = 0; i < feature.points.length; i++) {
        final pt = feature.points[i];
        final dx = pt[0] * scaleX;
        final dy = pt[1] * scaleY;
        if (i == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }
      path.close();

      final isHighlightedGate =
          feature.type == 'gate' &&
          highlightGate != null &&
          (feature.label?.toUpperCase() == highlightGate!.toUpperCase() ||
              feature.label?.toUpperCase().contains(
                    highlightGate!.toUpperCase(),
                  ) ==
                  true);

      final fill = _fillForType(feature.type, isHighlightedGate);
      final stroke = _strokeForType(feature.type, isHighlightedGate);

      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = isHighlightedGate ? 3 : 1.2,
      );

      if (feature.label != null && feature.points.isNotEmpty) {
        final cx =
            feature.points.map((p) => p[0]).reduce((a, b) => a + b) /
            feature.points.length;
        final cy =
            feature.points.map((p) => p[1]).reduce((a, b) => a + b) /
            feature.points.length;
        _drawLabel(
          canvas,
          feature.label!,
          cx * scaleX,
          cy * scaleY,
          isHighlightedGate,
        );
      }
    }

    for (final poi in pois) {
      if (poi.type == 'you') continue;
      _drawPoi(canvas, poi, scaleX, scaleY);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF112B4A)
      ..style = PaintingStyle.fill;
    for (var y = 0.0; y < size.height; y += 18) {
      for (var x = 0.0; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  Color _fillForType(String type, bool highlighted) {
    if (highlighted) return const Color(0x554A91F8);
    return switch (type) {
      'corridor' => const Color(0xFF1A3050),
      'gate' => const Color(0x334A91F8),
      'shop' => const Color(0x3348B8A9),
      'food' => const Color(0x33FFACA6),
      'lounge' => const Color(0x335B332F),
      'toilet' => const Color(0x33778899),
      'hall' => const Color(0xFF0C1B31),
      _ => const Color(0xFF152840),
    };
  }

  Color _strokeForType(String type, bool highlighted) {
    if (highlighted) return const Color(0xFF4A91F8);
    return switch (type) {
      'corridor' => const Color(0xFF2B4A70),
      'gate' => const Color(0xFF4A91F8),
      'shop' => const Color(0xFF48B8A9),
      'food' => const Color(0xFFFFACA6),
      'lounge' => const Color(0xFF8B6E66),
      'toilet' => const Color(0xFF778899),
      'hall' => const Color(0xFF314663),
      _ => const Color(0xFF314663),
    };
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, bool bold) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: bold ? const Color(0xFF4A91F8) : const Color(0xFFB4C0D6),
          fontSize: bold ? 11 : 9,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);
    painter.paint(
      canvas,
      Offset(x - painter.width / 2, y - painter.height / 2),
    );
  }

  void _drawPoi(Canvas canvas, IndoorPoi poi, double scaleX, double scaleY) {
    final center = Offset(poi.x * scaleX, poi.y * scaleY);
    final color = poi.type == 'you'
        ? const Color(0xFFFFACA6)
        : poi.type == 'gate'
        ? const Color(0xFF4A91F8)
        : const Color(0xFF48B8A9);

    canvas.drawCircle(
      center,
      10,
      Paint()..color = color.withValues(alpha: 0.25),
    );
    canvas.drawCircle(center, 5, Paint()..color = color);
    _drawLabel(canvas, poi.label, center.dx, center.dy + 14, poi.type == 'you');
  }

  @override
  bool shouldRepaint(covariant IndoorMapPainter oldDelegate) {
    return oldDelegate.features != features ||
        oldDelegate.pois != pois ||
        oldDelegate.highlightGate != highlightGate;
  }
}
