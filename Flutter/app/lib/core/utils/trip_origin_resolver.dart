import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/home_address.dart';

const demoOriginLatLng = LatLng(41.0369, 28.9850);

class TripOriginResolver {
  const TripOriginResolver._();

  static ({double lat, double lng, String? label, bool isManual}) resolve({
    required HomeAddress homeAddress,
    Position? gpsPosition,
  }) {
    if (homeAddress.isUsableManualOrigin) {
      return (
        lat: homeAddress.lat!,
        lng: homeAddress.lng!,
        label: homeAddress.address,
        isManual: true,
      );
    }
    if (gpsPosition != null) {
      return (
        lat: gpsPosition.latitude,
        lng: gpsPosition.longitude,
        label: null,
        isManual: false,
      );
    }
    return (
      lat: demoOriginLatLng.latitude,
      lng: demoOriginLatLng.longitude,
      label: null,
      isManual: false,
    );
  }
}
