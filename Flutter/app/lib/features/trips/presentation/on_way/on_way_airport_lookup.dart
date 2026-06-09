import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class AirportPoint {
  final String code;
  final double lat;
  final double lng;

  const AirportPoint(this.code, this.lat, this.lng);

  LatLng get latLng => LatLng(lat, lng);
}

AirportPoint airportFor(String? code) {
  return switch ((code ?? '').toUpperCase()) {
    'MJI' => const AirportPoint('MJI', 32.8941, 13.2760),
    'CAI' => const AirportPoint('CAI', 30.1219, 31.4056),
    'IST' => const AirportPoint('IST', 41.2753, 28.7519),
    'DXB' => const AirportPoint('DXB', 25.2532, 55.3657),
    'AMM' => const AirportPoint('AMM', 31.7225, 35.9932),
    'JED' => const AirportPoint('JED', 21.6796, 39.1565),
    'RUH' => const AirportPoint('RUH', 24.9576, 46.6988),
    'DOH' => const AirportPoint('DOH', 25.2731, 51.6081),
    'TUN' => const AirportPoint('TUN', 36.8510, 10.2272),
    'LHR' => const AirportPoint('LHR', 51.4700, -0.4543),
    'CDG' => const AirportPoint('CDG', 49.0097, 2.5479),
    'FCO' => const AirportPoint('FCO', 41.8003, 12.2389),
    'MAD' => const AirportPoint('MAD', 40.4983, -3.5676),
    'FRA' => const AirportPoint('FRA', 50.0379, 8.5622),
    'BCN' => const AirportPoint('BCN', 41.2974, 2.0833),
    'MUC' => const AirportPoint('MUC', 48.3538, 11.7861),
    'ADD' => const AirportPoint('ADD', 8.9806, 38.7992),
    'JFK' => const AirportPoint('JFK', 40.6413, -73.7781),
    _ => AirportPoint(code?.toUpperCase() ?? 'AIRPORT', 25.2532, 55.3657),
  };
}

double distanceKm(double lat1, double lon1, double lat2, double lon2) {
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

List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  while (index < encoded.length) {
    final latResult = _decodePolylineValue(encoded, index);
    lat += latResult.value;
    index = latResult.nextIndex;

    final lngResult = _decodePolylineValue(encoded, index);
    lng += lngResult.value;
    index = lngResult.nextIndex;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return points;
}

({int value, int nextIndex}) _decodePolylineValue(String encoded, int start) {
  var index = start;
  var shift = 0;
  var result = 0;
  int byte;
  do {
    byte = encoded.codeUnitAt(index++) - 63;
    result |= (byte & 0x1f) << shift;
    shift += 5;
  } while (byte >= 0x20 && index < encoded.length);

  final value = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  return (value: value, nextIndex: index);
}
