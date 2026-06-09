import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

final geocodingServiceProvider = Provider<GeocodingService>(
  (ref) => GeocodingService(ref.watch(apiClientProvider)),
);

class GeocodingService {
  GeocodingService(this._apiClient);

  final ApiClient _apiClient;

  Future<({String formattedAddress, double lat, double lng})> geocode(
    String address,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/maps/geocode',
      queryParameters: {'address': address.trim()},
    );
    final data = response.data ?? const {};
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    final formatted = data['formatted_address'] as String? ?? address.trim();
    if (lat == null || lng == null) {
      throw StateError('Geocoding returned no coordinates');
    }
    return (formattedAddress: formatted, lat: lat, lng: lng);
  }
}
