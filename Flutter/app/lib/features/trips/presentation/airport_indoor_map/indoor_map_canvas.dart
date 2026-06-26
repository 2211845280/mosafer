import 'package:flutter/material.dart';

import '../../domain/indoor_map.dart';
import 'indoor_map_painter.dart';
import 'indoor_route_builder.dart';
import 'indoor_route_painter.dart';
import '../../../../core/theme/app_theme_extension.dart';

/// Native indoor floor plan with pinch-zoom; route shares map coordinates.
class IndoorMapCanvas extends StatefulWidget {
  const IndoorMapCanvas({
    super.key,
    required this.map,
    required this.level,
    required this.highlightGate,
    required this.routeEnabled,
    required this.highlightPois,
    this.highlightCategory,
  });

  final IndoorMapData map;
  final String level;
  final String highlightGate;
  final bool routeEnabled;
  final List<IndoorPoi> highlightPois;
  final String? highlightCategory;

  @override
  State<IndoorMapCanvas> createState() => _IndoorMapCanvasState();
}

class _IndoorMapCanvasState extends State<IndoorMapCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _routeAnimation;

  @override
  void initState() {
    super.initState();
    _routeAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.routeEnabled) {
      _routeAnimation.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant IndoorMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routeEnabled && !_routeAnimation.isAnimating) {
      _routeAnimation.repeat();
    } else if (!widget.routeEnabled && _routeAnimation.isAnimating) {
      _routeAnimation.stop();
      _routeAnimation.value = 0;
    }
  }

  @override
  void dispose() {
    _routeAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final features = widget.map.featuresForLevel(widget.level);
    final pois = widget.map.poisForLevel(widget.level);
    final routePoints = widget.routeEnabled
        ? buildIndoorRoutePath(
            map: widget.map,
            level: widget.level,
            gate: widget.highlightGate,
          )
        : const <Offset>[];

    return AspectRatio(
      aspectRatio: 1,
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(48),
        minScale: 0.92,
        maxScale: 4,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: indoorMapCoordinateSize,
          height: indoorMapCoordinateSize,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: IndoorMapPainter(
                  features: features,
                  pois: pois,
                  highlightGate: widget.highlightGate,
                ),
              ),
              if (routePoints.length >= 2)
                AnimatedBuilder(
                  animation: _routeAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: IndoorRoutePainter(
                        routePoints: routePoints,
                        progress: _routeAnimation.value,
                      ),
                    );
                  },
                ),
              if (widget.highlightPois.isNotEmpty)
                CustomPaint(
                  painter: _AmenityPinsPainter(
                    pois: widget.highlightPois,
                    category: widget.highlightCategory,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmenityPinsPainter extends CustomPainter {
  const _AmenityPinsPainter({required this.pois, this.category});

  final List<IndoorPoi> pois;
  final String? category;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / indoorMapCoordinateSize;
    final scaleY = size.height / indoorMapCoordinateSize;
    final pinColor = category == 'coffee'
        ? const Color(0xFFFFB74D)
        : const Color(0xFF81C784);

    for (final poi in pois) {
      final center = Offset(poi.x * scaleX, poi.y * scaleY);
      canvas.drawCircle(center, 16, Paint()..color = const Color(0x99061326));
      canvas.drawCircle(center, 12, Paint()..color = pinColor);
      canvas.drawCircle(
        center,
        5,
        Paint()..color = const Color(0xFF061326),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmenityPinsPainter oldDelegate) {
    return oldDelegate.pois != pois || oldDelegate.category != category;
  }
}
