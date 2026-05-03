import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/location_service.dart';
import '../active_trip_controller.dart';

class OnWayPage extends ConsumerStatefulWidget {
  const OnWayPage({super.key});

  @override
  ConsumerState<OnWayPage> createState() => _OnWayPageState();
}

class _OnWayPageState extends ConsumerState<OnWayPage> {
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  bool _isTracking = false;
  String? _message;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(activeTripProvider);
    final airport = _airportFor(trip?.fromCode);
    final distanceKm = _currentPosition == null
        ? null
        : _distanceKm(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            airport.lat,
            airport.lng,
          );

    return Scaffold(
      backgroundColor: _OnWayColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 124),
              sliver: SliverList.list(
                children: [
                  const Text(
                    'On way',
                    style: TextStyle(
                      color: _OnWayColors.title,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From your current location to ${airport.code} airport',
                    style: const TextStyle(
                      color: _OnWayColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RouteMapCard(
                    airport: airport,
                    hasLiveLocation: _currentPosition != null,
                    isTracking: _isTracking,
                  ),
                  const SizedBox(height: 18),
                  _RouteStatsCard(
                    distanceKm: distanceKm,
                    isTracking: _isTracking,
                    message: _message,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isTracking ? null : _startNavigation,
              icon: const Icon(Icons.navigation),
              label: Text(
                _isTracking ? 'TRACKING STARTED' : 'START NAVIGATION',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startNavigation() async {
    final firstPosition = await _locationService.currentPosition();
    if (!mounted) return;
    if (firstPosition == null) {
      setState(
        () => _message = 'Location permission or service is not available.',
      );
      return;
    }

    setState(() {
      _currentPosition = firstPosition;
      _isTracking = true;
      _message = 'Live tracking is active.';
    });

    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          if (mounted) {
            setState(() => _currentPosition = position);
          }
        });
  }
}

class _RouteMapCard extends StatelessWidget {
  final _AirportPoint airport;
  final bool hasLiveLocation;
  final bool isTracking;

  const _RouteMapCard({
    required this.airport,
    required this.hasLiveLocation,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      decoration: BoxDecoration(
        color: _OnWayColors.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(
                painter: _OnWayMapPainter(isTracking: isTracking),
              ),
            ),
          ),
          const Positioned(
            left: 28,
            bottom: 40,
            child: _MapPoint(label: 'YOU', icon: Icons.person_pin_circle),
          ),
          Positioned(
            right: 26,
            top: 48,
            child: _MapPoint(label: airport.code, icon: Icons.local_airport),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Text(
              hasLiveLocation
                  ? 'Live location connected'
                  : 'Press Start Navigation to connect live location',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _OnWayColors.title,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnWayMapPainter extends CustomPainter {
  final bool isTracking;

  const _OnWayMapPainter({required this.isTracking});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0.0; i < size.width; i += 28) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (var i = 0.0; i < size.height; i += 28) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.75)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.55,
        size.width * 0.58,
        size.height * 0.58,
        size.width * 0.72,
        size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.29,
        size.width * 0.84,
        size.height * 0.23,
        size.width * 0.88,
        size.height * 0.19,
      );

    final routePaint = Paint()
      ..color = isTracking ? _OnWayColors.salmon : _OnWayColors.blue
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant _OnWayMapPainter oldDelegate) {
    return oldDelegate.isTracking != isTracking;
  }
}

class _MapPoint extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MapPoint({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _OnWayColors.blue,
          child: Icon(icon, color: _OnWayColors.background, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: _OnWayColors.title,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _RouteStatsCard extends StatelessWidget {
  final double? distanceKm;
  final bool isTracking;
  final String? message;

  const _RouteStatsCard({
    required this.distanceKm,
    required this.isTracking,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final etaMinutes = distanceKm == null
        ? null
        : (distanceKm! / 55 * 60).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _OnWayColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _StatRow(
            icon: Icons.route,
            label: 'Distance',
            value: distanceKm == null
                ? '-- km'
                : '${distanceKm!.toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.timer_outlined,
            label: 'ETA',
            value: etaMinutes == null ? '-- mins' : '$etaMinutes mins',
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
            label: 'Tracking',
            value: isTracking ? 'Active' : 'Not started',
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _OnWayColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: _OnWayColors.iconBackground,
          child: Icon(icon, color: _OnWayColors.title, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _OnWayColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _OnWayColors.title,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AirportPoint {
  final String code;
  final double lat;
  final double lng;

  const _AirportPoint(this.code, this.lat, this.lng);
}

_AirportPoint _airportFor(String? code) {
  return switch ((code ?? '').toUpperCase()) {
    'CAI' => const _AirportPoint('CAI', 30.1219, 31.4056),
    'DXB' => const _AirportPoint('DXB', 25.2532, 55.3657),
    'LHR' => const _AirportPoint('LHR', 51.4700, -0.4543),
    'JFK' => const _AirportPoint('JFK', 40.6413, -73.7781),
    _ => _AirportPoint(code?.toUpperCase() ?? 'AIRPORT', 25.2532, 55.3657),
  };
}

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const radiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return radiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _degToRad(double value) => value * math.pi / 180;

class _OnWayColors {
  _OnWayColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color title = Color(0xFFD5E4FF);
  static const Color muted = Color(0xFF8FA0BA);
  static const Color blue = Color(0xFF4A91F8);
  static const Color salmon = Color(0xFFFFACA6);
  static const Color iconBackground = Color(0xFF1D2D46);
}
