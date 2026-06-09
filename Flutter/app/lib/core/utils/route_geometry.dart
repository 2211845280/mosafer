/// Helpers for deciding whether a polyline follows roads or is just a straight segment.
library;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A real driving route from Google typically contains dozens of points.
bool isDetailedRoadRoute(List<LatLng> points) => points.length > 2;

/// Two-point segments are straight lines and should not be shown as road routes.
bool isStraightLineRoute(List<LatLng> points) =>
    points.length == 2 &&
    points.first.latitude == points.last.latitude &&
    points.first.longitude == points.last.longitude;
