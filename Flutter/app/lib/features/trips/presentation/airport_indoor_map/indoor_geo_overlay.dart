import 'package:flutter/material.dart';

import '../../domain/indoor_map.dart';
import 'indoor_geo_projector.dart';

/// Markers and route polyline on top of OpenLevelUp (real OSM indoor map).
class IndoorGeoOverlay extends StatefulWidget {
  const IndoorGeoOverlay({
    super.key,
    required this.map,
    required this.routeEnabled,
    required this.highlightPois,
    this.highlightCategory,
  });

  final IndoorMapData map;
  final bool routeEnabled;
  final List<IndoorPoi> highlightPois;
  final String? highlightCategory;

  @override
  State<IndoorGeoOverlay> createState() => _IndoorGeoOverlayState();
}

class _IndoorGeoOverlayState extends State<IndoorGeoOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.routeEnabled) {
      _pulse.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant IndoorGeoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routeEnabled && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.routeEnabled) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = widget.map.viewport;
    if (viewport == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final projector = IndoorGeoProjector(
          centerLat: viewport.centerLat,
          centerLng: viewport.centerLng,
          zoom: viewport.zoom,
          offsetY: -8,
        );

        final routeLatLng = widget.routeEnabled
            ? widget.map.routePoints
                  .where((p) => p.hasGeo)
                  .map((p) => Offset(p.lat!, p.lng!))
                  .toList()
            : <Offset>[];

        final markers = <_MapMarker>[
          if (widget.map.userLocation?.hasGeo == true)
            _MapMarker(
              lat: widget.map.userLocation!.lat!,
              lng: widget.map.userLocation!.lng!,
              label: widget.map.userLocation!.label ?? 'You',
              color: const Color(0xFF2CE59B),
              icon: Icons.person_pin_circle,
              size: 28,
            ),
          if (widget.map.gateLocation?.hasGeo == true)
            _MapMarker(
              lat: widget.map.gateLocation!.lat!,
              lng: widget.map.gateLocation!.lng!,
              label: widget.map.gateLocation!.label ?? 'Gate',
              color: const Color(0xFFFF8B6E),
              icon: Icons.flight,
              size: 32,
            ),
          for (final poi in widget.highlightPois.where((p) => p.hasGeo))
            _MapMarker(
              lat: poi.lat!,
              lng: poi.lng!,
              label: poi.label,
              color: widget.highlightCategory == 'coffee'
                  ? const Color(0xFFFFB74D)
                  : const Color(0xFF81C784),
              icon: widget.highlightCategory == 'coffee'
                  ? Icons.local_cafe
                  : Icons.restaurant,
              size: 24,
            ),
        ];

        return IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (routeLatLng.length >= 2)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _GeoRoutePainter(
                          projector: projector,
                          routeLatLng: routeLatLng,
                          viewSize: size,
                          progress: _pulse.value,
                        ),
                      );
                    },
                  ),
                ),
              for (final marker in markers)
                _buildMarker(projector, size, marker),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarker(
    IndoorGeoProjector projector,
    Size size,
    _MapMarker marker,
  ) {
    final pos = projector.project(marker.lat, marker.lng, size);
    return Positioned(
      left: pos.dx - marker.size / 2,
      top: pos.dy - marker.size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(marker.icon, color: marker.color, size: marker.size),
          const SizedBox(height: 2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xE0061326),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                marker.label,
                style: const TextStyle(
                  color: Color(0xFFD5E4FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker {
  final double lat;
  final double lng;
  final String label;
  final Color color;
  final IconData icon;
  final double size;

  const _MapMarker({
    required this.lat,
    required this.lng,
    required this.label,
    required this.color,
    required this.icon,
    required this.size,
  });
}

class _GeoRoutePainter extends CustomPainter {
  const _GeoRoutePainter({
    required this.projector,
    required this.routeLatLng,
    required this.viewSize,
    required this.progress,
  });

  final IndoorGeoProjector projector;
  final List<Offset> routeLatLng;
  final Size viewSize;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final points = routeLatLng
        .map((p) => projector.project(p.dy, p.dx, viewSize))
        .toList();
    if (points.length < 2) {
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xAA061326)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4A91F8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(metric.length * progress);
    final dot = tangent?.position ?? points.last;
    canvas.drawCircle(dot, 8, Paint()..color = const Color(0xAA061326));
    canvas.drawCircle(dot, 5, Paint()..color = const Color(0xFFFF8B6E));
  }

  @override
  bool shouldRepaint(covariant _GeoRoutePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.routeLatLng != routeLatLng;
  }
}
