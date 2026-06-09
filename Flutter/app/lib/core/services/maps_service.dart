import 'package:url_launcher/url_launcher.dart';

class MapsService {
  Future<bool> openDirections({
    required String destination,
    String travelMode = 'driving',
  }) async {
    final encodedDestination = Uri.encodeComponent(destination);
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$encodedDestination&travelmode=$travelMode',
    );
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<bool> openDirectionsToCoordinates({
    required double destinationLat,
    required double destinationLng,
    double? originLat,
    double? originLng,
    String travelMode = 'driving',
  }) async {
    final destination = '$destinationLat,$destinationLng';
    final query = <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': travelMode,
    };
    if (originLat != null && originLng != null) {
      query['origin'] = '$originLat,$originLng';
    }
    final uri = Uri.https('www.google.com', '/maps/dir/', query);
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<bool> openAirportMap(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
