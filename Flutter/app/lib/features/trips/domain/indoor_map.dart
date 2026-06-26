class IndoorMapData {
  final String airportIata;
  final String airportName;
  final String defaultLevel;
  final List<IndoorLevel> levels;
  final List<IndoorFeature> features;
  final List<IndoorPoi> pois;
  final String source;
  final bool isFallback;
  final bool supported;
  final String? message;
  final String? highlightGate;
  final String? highlightCategory;
  final List<IndoorPoi> highlightPois;
  final IndoorMapViewport? viewport;
  final GeoPoint? userLocation;
  final GeoPoint? gateLocation;
  final List<GeoPoint> routePoints;

  const IndoorMapData({
    required this.airportIata,
    required this.airportName,
    required this.defaultLevel,
    required this.levels,
    required this.features,
    required this.pois,
    required this.source,
    required this.isFallback,
    required this.supported,
    this.message,
    this.highlightGate,
    this.highlightCategory,
    this.highlightPois = const [],
    this.viewport,
    this.userLocation,
    this.gateLocation,
    this.routePoints = const [],
  });

  /// Curated IST layout used when the API is unreachable (Flutter-side fallback).
  factory IndoorMapData.istOfflineFallback({String? gate, String? highlightCategory}) {
    final normalizedGate = gate?.trim().toUpperCase();
    return IndoorMapData(
      airportIata: 'IST',
      airportName: 'Istanbul Airport',
      defaultLevel: '0',
      levels: const [
        IndoorLevel(id: '-1', label: 'Arrivals / Lower Level'),
        IndoorLevel(id: '0', label: 'Main Terminal'),
        IndoorLevel(id: '1', label: 'Departures / Gates'),
      ],
      features: const [
        IndoorFeature(
          id: 'gate-g12',
          type: 'gate',
          level: '1',
          label: 'G12',
          points: [
            [860, 500],
            [900, 500],
            [900, 540],
            [860, 540],
            [860, 500],
          ],
        ),
        IndoorFeature(
          id: 'gate-g6',
          type: 'gate',
          level: '1',
          label: 'G6',
          points: [
            [360, 500],
            [400, 500],
            [400, 540],
            [360, 540],
            [360, 500],
          ],
        ),
      ],
      pois: const [
        IndoorPoi(
          id: 'poi-g12',
          type: 'gate',
          level: '1',
          label: 'G12',
          x: 880,
          y: 520,
        ),
        IndoorPoi(
          id: 'poi-g6',
          type: 'gate',
          level: '1',
          label: 'G6',
          x: 380,
          y: 520,
        ),
        IndoorPoi(
          id: 'poi-coffee-g12',
          type: 'coffee',
          level: '1',
          label: 'Starbucks Gate Area',
          x: 760,
          y: 400,
        ),
      ],
      source: 'offline_fallback',
      isFallback: true,
      supported: true,
      message: 'Using offline Istanbul Airport layout.',
      highlightGate: normalizedGate,
      highlightCategory: highlightCategory,
      viewport: const IndoorMapViewport(
        centerLat: 41.2622,
        centerLng: 28.7425,
        zoom: 17,
        openLevelupLevel: '1',
      ),
    );
  }

  factory IndoorMapData.fromJson(Map<String, dynamic> json) {
    return IndoorMapData(
      airportIata: json['airport_iata'] as String? ?? '',
      airportName: json['airport_name'] as String? ?? '',
      defaultLevel: json['default_level'] as String? ?? '0',
      levels: (json['levels'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(IndoorLevel.fromJson)
          .toList(),
      features: (json['features'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(IndoorFeature.fromJson)
          .toList(),
      pois: (json['pois'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(IndoorPoi.fromJson)
          .toList(),
      source: json['source'] as String? ?? 'fallback',
      isFallback: json['is_fallback'] as bool? ?? true,
      supported: json['supported'] as bool? ?? false,
      message: json['message'] as String?,
      highlightGate: json['highlight_gate'] as String?,
      highlightCategory: json['highlight_category'] as String?,
      highlightPois: (json['highlight_pois'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(IndoorPoi.fromJson)
          .toList(),
      viewport: json['viewport'] is Map<String, dynamic>
          ? IndoorMapViewport.fromJson(
              json['viewport'] as Map<String, dynamic>,
            )
          : null,
      userLocation: json['user_location'] is Map<String, dynamic>
          ? GeoPoint.fromJson(json['user_location'] as Map<String, dynamic>)
          : null,
      gateLocation: json['gate_location'] is Map<String, dynamic>
          ? GeoPoint.fromJson(json['gate_location'] as Map<String, dynamic>)
          : null,
      routePoints: (json['route_points'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GeoPoint.fromJson)
          .toList(),
    );
  }

  List<IndoorFeature> featuresForLevel(String level) =>
      features.where((f) => f.level == level).toList();

  List<IndoorPoi> poisForLevel(String level) =>
      pois.where((p) => p.level == level).toList();

  /// Resolve indoor level for a gate label (e.g. G12) from features or POIs.
  String? levelForGate(String gate) {
    final normalized = gate.trim().toUpperCase();
    for (final feature in features) {
      if (feature.type == 'gate' &&
          feature.label?.trim().toUpperCase() == normalized) {
        return feature.level;
      }
    }
    for (final poi in pois) {
      if (poi.type == 'gate' && poi.label.trim().toUpperCase() == normalized) {
        return poi.level;
      }
    }
    return null;
  }
}

class GeoPoint {
  final double? lat;
  final double? lng;
  final String? label;

  const GeoPoint({this.lat, this.lng, this.label});

  bool get hasGeo => lat != null && lng != null;

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      label: json['label'] as String?,
    );
  }
}

class IndoorMapViewport {
  final double centerLat;
  final double centerLng;
  final int zoom;
  final String openLevelupLevel;

  const IndoorMapViewport({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.openLevelupLevel,
  });

  factory IndoorMapViewport.fromJson(Map<String, dynamic> json) {
    return IndoorMapViewport(
      centerLat: (json['center_lat'] as num).toDouble(),
      centerLng: (json['center_lng'] as num).toDouble(),
      zoom: (json['zoom'] as num?)?.round() ?? 17,
      openLevelupLevel: json['open_levelup_level'] as String? ?? '1',
    );
  }
}

class IndoorLevel {
  final String id;
  final String label;

  const IndoorLevel({required this.id, required this.label});

  factory IndoorLevel.fromJson(Map<String, dynamic> json) {
    return IndoorLevel(
      id: json['id'] as String? ?? '0',
      label: json['label'] as String? ?? 'Level',
    );
  }
}

class IndoorFeature {
  final String id;
  final String type;
  final String level;
  final String? label;
  final List<List<double>> points;

  const IndoorFeature({
    required this.id,
    required this.type,
    required this.level,
    this.label,
    required this.points,
  });

  factory IndoorFeature.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List? ?? const [];
    return IndoorFeature(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'room',
      level: json['level'] as String? ?? '0',
      label: json['label'] as String?,
      points: rawPoints
          .whereType<List>()
          .map(
            (pair) =>
                pair.map((v) => (v as num).toDouble()).toList(growable: false),
          )
          .toList(),
    );
  }
}

class IndoorPoi {
  final String id;
  final String type;
  final String level;
  final String label;
  final double x;
  final double y;
  final double? lat;
  final double? lng;

  const IndoorPoi({
    required this.id,
    required this.type,
    required this.level,
    required this.label,
    required this.x,
    required this.y,
    this.lat,
    this.lng,
  });

  bool get hasGeo => lat != null && lng != null;

  factory IndoorPoi.fromJson(Map<String, dynamic> json) {
    return IndoorPoi(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'poi',
      level: json['level'] as String? ?? '0',
      label: json['label'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
