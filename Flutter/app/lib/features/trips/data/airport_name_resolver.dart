import '../../../core/network/api_client.dart';

class AirportNameResolver {
  AirportNameResolver(this._apiClient);

  final ApiClient _apiClient;
  final Map<String, String> _cache = {};

  Future<String> resolve(String iata) async {
    final code = iata.trim().toUpperCase();
    if (code.isEmpty) {
      return iata;
    }
    final cached = _cache[code];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/airports/$code/info',
      );
      final name = response.data?['name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        _cache[code] = name.trim();
        return _cache[code]!;
      }
    } catch (_) {
      // Fall back to IATA code when airport info is unavailable.
    }

    _cache[code] = code;
    return code;
  }

  Future<Map<String, String>> resolveMany(Iterable<String> codes) async {
    final unique = codes
        .map((code) => code.trim().toUpperCase())
        .where((code) => code.isNotEmpty)
        .toSet();
    await Future.wait(unique.map(resolve));
    return Map.fromEntries(unique.map((code) => MapEntry(code, _cache[code] ?? code)));
  }
}
