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
