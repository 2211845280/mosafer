import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'on_way_airport_lookup.dart';

class OnWayMapArgs {
  final String airportCode;
  final String airportName;
  final LatLng airport;
  final LatLng? origin;
  final List<LatLng> routePoints;
  final bool isTracking;
  final bool showLiveLocation;
  final String? mapCaption;
  final String originLabel;

  const OnWayMapArgs({
    required this.airportCode,
    required this.airportName,
    required this.airport,
    this.origin,
    this.routePoints = const [],
    this.isTracking = false,
    this.showLiveLocation = false,
    this.mapCaption,
    required this.originLabel,
  });

  factory OnWayMapArgs.fromPageState({
    required String? fromCode,
    required String fromCity,
    required AirportPoint mapAirport,
    required Position? currentPosition,
    required LatLng? routeOrigin,
    required List<LatLng> routePoints,
    required bool isTracking,
    required String originLabel,
    required String? mapCaption,
  }) {
    final userLatLng = currentPosition == null
        ? null
        : LatLng(currentPosition.latitude, currentPosition.longitude);

    return OnWayMapArgs(
      airportCode: mapAirport.code,
      airportName: fromCity.trim().isNotEmpty ? fromCity : mapAirport.code,
      airport: mapAirport.latLng,
      origin: userLatLng ?? routeOrigin,
      routePoints: routePoints,
      isTracking: isTracking,
      showLiveLocation: currentPosition != null,
      mapCaption: mapCaption,
      originLabel: originLabel,
    );
  }
}
