import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/app_constants.dart';
import '../network/api_client.dart';

enum GoogleTravelMode { driving, walking, transit }

class GoogleDirectionsRoute {
  const GoogleDirectionsRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.encodedPolyline,
    this.provider,
    this.routeIndex = 0,
    this.summary,
  });

  final List<LatLng> points;
  final int distanceMeters;
  final int durationSeconds;
  final String? encodedPolyline;
  final String? provider;
  final int routeIndex;
  final String? summary;

  double get distanceKm => distanceMeters / 1000;

  int get durationMinutes =>
      durationSeconds <= 0 ? 0 : (durationSeconds / 60).ceil().clamp(1, 9999);
}

class GoogleDirectionsException implements Exception {
  GoogleDirectionsException(this.message, {this.status});

  final String message;
  final String? status;

  @override
  String toString() => status == null ? message : '$message ($status)';
}

/// Fetches road-following routes.
///
/// - Web: uses backend /maps/directions.
/// - Mobile/desktop native: tries backend first, then Google Directions REST.
///
/// Important:
/// This service rejects routes with only 2 points because those are usually
/// straight-line fallback routes, not real road-following routes.
class GoogleDirectionsService {
  GoogleDirectionsService({
    PolylinePoints? polylinePoints,
    Dio? dio,
    ApiClient? apiClient,
    String? apiKey,
    Duration timeout = const Duration(seconds: 12),
  }) : _polylinePoints = polylinePoints ?? PolylinePoints(),
       _dio = dio ?? Dio(),
       _apiClient = apiClient,
       _apiKey = apiKey ?? AppConstants.googleMapsApiKey,
       _timeout = timeout;

  final PolylinePoints _polylinePoints;
  final Dio _dio;
  final ApiClient? _apiClient;
  final String _apiKey;
  final Duration _timeout;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  List<LatLng> decodePolyline(String encoded) {
    if (encoded.trim().isEmpty) {
      return const [];
    }

    return _polylinePoints
        .decodePolyline(encoded)
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
  }

  /// This is only fallback.
  /// Do not treat it as a real road route because it returns only 2 points.
  List<LatLng> straightLineFallback(LatLng origin, LatLng destination) {
    return [origin, destination];
  }

  Future<GoogleDirectionsRoute?> tryGetRoute({
    required LatLng origin,
    required LatLng destination,
    GoogleTravelMode mode = GoogleTravelMode.driving,
  }) async {
    final alternatives = await tryGetRouteAlternatives(
      origin: origin,
      destination: destination,
      mode: mode,
    );

    if (alternatives.isEmpty) {
      return null;
    }

    return _fastestRoute(alternatives);
  }

  Future<List<GoogleDirectionsRoute>> tryGetRouteAlternatives({
    required LatLng origin,
    required LatLng destination,
    GoogleTravelMode mode = GoogleTravelMode.driving,
  }) async {
    final backendRoutes = await _tryBackendRouteAlternatives(
      origin: origin,
      destination: destination,
      mode: mode,
    );

    if (backendRoutes.isNotEmpty) {
      debugPrint('Backend route alternatives count: ${backendRoutes.length}');
      return backendRoutes;
    }

    if (!kIsWeb && isConfigured) {
      try {
        final directRoutes = await getRouteAlternatives(
          origin: origin,
          destination: destination,
          mode: mode,
        );

        debugPrint('Google direct route alternatives count: ${directRoutes.length}');
        return directRoutes;
      } on GoogleDirectionsException catch (e) {
        debugPrint('Google Directions exception: $e');
      } on Exception catch (e) {
        debugPrint('Google Directions unknown error: $e');
      }
    }

    return const [];
  }

  Future<List<GoogleDirectionsRoute>> _tryBackendRouteAlternatives({
    required LatLng origin,
    required LatLng destination,
    required GoogleTravelMode mode,
  }) async {
    final client = _apiClient;
    if (client == null) {
      return const [];
    }

    try {
      final response = await client
          .get<Map<String, dynamic>>(
            '/maps/directions',
            queryParameters: {
              'origin_lat': origin.latitude,
              'origin_lng': origin.longitude,
              'dest_lat': destination.latitude,
              'dest_lng': destination.longitude,
              'mode': _modeQuery(mode),
            },
          )
          .timeout(_timeout);

      final data = response.data ?? const {};
      final rawRoutes = data['routes'] as List<dynamic>? ?? const [];

      if (rawRoutes.isNotEmpty) {
        final parsed = <GoogleDirectionsRoute>[];
        for (final item in rawRoutes) {
          if (item is! Map<String, dynamic>) {
            continue;
          }
          final route = _parseBackendRouteOption(item);
          if (route != null) {
            parsed.add(route);
          }
        }
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }

      final fallbackRoute = _parseBackendRouteOption(data);
      return fallbackRoute == null ? const [] : [fallbackRoute];
    } on Exception catch (e) {
      debugPrint('Backend directions error: $e');
      return const [];
    }
  }

  GoogleDirectionsRoute? _parseBackendRouteOption(Map<String, dynamic> data) {
    final encoded = data['encoded_polyline'] as String?;
    if (encoded == null || encoded.trim().isEmpty) {
      debugPrint('Backend route: encoded polyline is empty');
      return null;
    }

    final points = decodePolyline(encoded);

    debugPrint('Backend decoded points count: ${points.length}');
    debugPrint('Backend encoded polyline length: ${encoded.length}');

    if (points.length <= 2) {
      debugPrint('Backend route rejected because it has <= 2 points');
      return null;
    }

    final distanceKm = (data['distance_km'] as num?)?.toDouble() ?? 0;
    final travelMinutes = (data['travel_minutes'] as num?)?.round() ?? 0;

    return GoogleDirectionsRoute(
      points: points,
      distanceMeters: (distanceKm * 1000).round(),
      durationSeconds: travelMinutes * 60,
      encodedPolyline: encoded,
      provider: data['provider'] as String? ?? 'backend',
      routeIndex: (data['route_index'] as num?)?.round() ?? 0,
      summary: data['summary'] as String?,
    );
  }

  Future<GoogleDirectionsRoute> getRoute({
    required LatLng origin,
    required LatLng destination,
    GoogleTravelMode mode = GoogleTravelMode.driving,
  }) async {
    final routes = await getRouteAlternatives(
      origin: origin,
      destination: destination,
      mode: mode,
    );

    if (routes.isEmpty) {
      throw GoogleDirectionsException('Directions returned no valid routes');
    }

    return _fastestRoute(routes);
  }

  Future<List<GoogleDirectionsRoute>> getRouteAlternatives({
    required LatLng origin,
    required LatLng destination,
    GoogleTravelMode mode = GoogleTravelMode.driving,
  }) async {
    if (!isConfigured) {
      throw GoogleDirectionsException(
        'Google Maps API key is missing. '
        'Pass --dart-define=MAPS_API_KEY=YOUR_KEY',
      );
    }

    final response = await _dio
        .get<Map<String, dynamic>>(
          'https://maps.googleapis.com/maps/api/directions/json',
          queryParameters: {
            'origin': '${origin.latitude},${origin.longitude}',
            'destination': '${destination.latitude},${destination.longitude}',
            'mode': _modeQuery(mode),
            'alternatives': 'true',
            'key': _apiKey,
          },
          options: Options(responseType: ResponseType.json),
        )
        .timeout(_timeout);

    final payload = response.data ?? const {};
    final status = payload['status'] as String? ?? 'UNKNOWN';

    debugPrint('Google Directions status: $status');

    if (status.toUpperCase() != 'OK') {
      throw GoogleDirectionsException(
        payload['error_message'] as String? ?? 'Directions request failed',
        status: status,
      );
    }

    final routes = payload['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      throw GoogleDirectionsException(
        'Directions returned no routes',
        status: status,
      );
    }

    final parsed = <GoogleDirectionsRoute>[];
    for (var index = 0; index < routes.length; index++) {
      final route = routes[index];
      if (route is! Map<String, dynamic>) {
        continue;
      }

      final parsedRoute = _parseGoogleRouteOption(route, index);
      if (parsedRoute != null) {
        parsed.add(parsedRoute);
      }
    }

    if (parsed.isEmpty) {
      throw GoogleDirectionsException('Directions returned no valid route points');
    }

    return parsed;
  }

  GoogleDirectionsRoute? _parseGoogleRouteOption(
    Map<String, dynamic> route,
    int routeIndex,
  ) {
    final encodedOverview =
        ((route['overview_polyline'] as Map<String, dynamic>?)?['points']
            as String?);

    final stepPoints = _decodeStepPolylines(route);

    final points = stepPoints.isNotEmpty
        ? stepPoints
        : (encodedOverview == null
              ? const <LatLng>[]
              : decodePolyline(encodedOverview));

    if (points.length <= 2) {
      debugPrint(
        'Google route $routeIndex rejected because it has <= 2 points',
      );
      return null;
    }

    final legs = route['legs'] as List<dynamic>? ?? const [];

    var distanceMeters = 0;
    var durationSeconds = 0;

    for (final leg in legs) {
      final legMap = leg as Map<String, dynamic>;

      distanceMeters += (legMap['distance'] as Map?)?['value'] as int? ?? 0;
      durationSeconds += (legMap['duration'] as Map?)?['value'] as int? ?? 0;
    }

    return GoogleDirectionsRoute(
      points: points,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      encodedPolyline: encodedOverview,
      provider: 'google_directions',
      routeIndex: routeIndex,
      summary: route['summary'] as String?,
    );
  }

  GoogleDirectionsRoute _fastestRoute(List<GoogleDirectionsRoute> routes) {
    final sorted = List<GoogleDirectionsRoute>.from(routes)
      ..sort((a, b) {
        final durationCompare = a.durationSeconds.compareTo(b.durationSeconds);
        if (durationCompare != 0) {
          return durationCompare;
        }
        return a.distanceMeters.compareTo(b.distanceMeters);
      });
    return sorted.first;
  }

  List<LatLng> _decodeStepPolylines(Map<String, dynamic> route) {
    final legs = route['legs'] as List<dynamic>? ?? const [];
    final merged = <LatLng>[];

    for (final leg in legs) {
      final legMap = leg as Map<String, dynamic>;

      final steps = legMap['steps'] as List<dynamic>? ?? const [];

      for (final step in steps) {
        final stepMap = step as Map<String, dynamic>;

        final encoded =
            ((stepMap['polyline'] as Map<String, dynamic>?)?['points']
                as String?) ??
            '';

        if (encoded.isEmpty) continue;

        final decoded = decodePolyline(encoded);

        if (decoded.isEmpty) continue;

        if (merged.isNotEmpty && _samePoint(merged.last, decoded.first)) {
          merged.addAll(decoded.skip(1));
        } else {
          merged.addAll(decoded);
        }
      }
    }

    return merged;
  }

  bool _samePoint(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }

  String _modeQuery(GoogleTravelMode mode) {
    return switch (mode) {
      GoogleTravelMode.walking => 'walking',
      GoogleTravelMode.transit => 'transit',
      GoogleTravelMode.driving => 'driving',
    };
  }
}
