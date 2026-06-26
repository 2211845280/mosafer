import 'package:app/core/services/notification_services.dart';
import 'package:app/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/debug/screenshot_mode.dart';
import '/core/localization/accept_language_holder.dart';
import '/core/localization/locale_providers.dart';
import '/core/theme/theme_mode_provider.dart';

/// When `ar`, forces Arabic UI for documentation capture (`--dart-define=DOC_CAPTURE_LOCALE=ar`).
const String kDocCaptureLocale = String.fromEnvironment('DOC_CAPTURE_LOCALE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await NotificationService.instance.init();
  }
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('app_locale');
  final initial = kDocCaptureLocale == 'ar'
      ? 'ar'
      : (saved == 'ar' ? 'ar' : 'en');
  final savedTheme = prefs.getString('app_theme_mode');
  final initialTheme = savedTheme == 'light' ? 'light' : 'dark';
  AcceptLanguageHolder.value = initial;
  runApp(
    ProviderScope(
      overrides: [
        savedLocaleOnStartupProvider.overrideWith((ref) => initial),
        savedThemeModeOnStartupProvider.overrideWith((ref) => initialTheme),
        if (kScreenshotMode) ...screenshotModeOverrides(),
      ],
      child: const App(),
    ),
  );
}
