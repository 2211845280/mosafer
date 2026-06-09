import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/localization/accept_language_holder.dart';
import 'core/localization/locale_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase config is optional in local development; REST features still run.
  }
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('app_locale');
  final initial = saved == 'ar' ? 'ar' : 'en';
  AcceptLanguageHolder.value = initial;
  runApp(
    ProviderScope(
      overrides: [savedLocaleOnStartupProvider.overrideWith((ref) => initial)],
      child: const App(),
    ),
  );
}
