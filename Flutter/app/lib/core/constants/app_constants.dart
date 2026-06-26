import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Mosafer';
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _webBaseUrlOverride = String.fromEnvironment(
    'WEB_BASE_URL',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001/api/v1';
    }

    return 'http://localhost:8001/api/v1';
  }

  /// Base URL for the Next.js booking site (no trailing slash).
  /// Override via: `--dart-define=WEB_BASE_URL=https://yourdomain.com`
  static String get webAppBaseUrl {
    if (_webBaseUrlOverride.isNotEmpty) {
      return _stripTrailingSlashes(_webBaseUrlOverride);
    }

    final apiUrl = Uri.tryParse(apiBaseUrl);
    if (apiUrl != null && apiUrl.host.isNotEmpty) {
      final scheme = apiUrl.scheme.isNotEmpty ? apiUrl.scheme : 'http';
      return '$scheme://${apiUrl.host}:3000';
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  /// Booking homepage with locale prefix (`/en` or `/ar`).
  static Uri bookingWebsiteUrl(String locale) {
    final normalized = locale == 'ar' ? 'ar' : 'en';
    return Uri.parse('${webAppBaseUrl}/$normalized');
  }

  static String _stripTrailingSlashes(String value) {
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';

  /// Client-side Google Maps key for Directions API calls from Flutter.
  /// Pass via: `--dart-define=MAPS_API_KEY=YOUR_KEY`
  static const String googleMapsApiKey = String.fromEnvironment('MAPS_API_KEY');
}
