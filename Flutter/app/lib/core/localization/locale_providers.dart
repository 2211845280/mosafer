import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accept_language_holder.dart';

/// Overridden in [main] after reading [SharedPreferences].
final savedLocaleOnStartupProvider = Provider<String>((ref) => 'en');

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);

class AppLocaleNotifier extends Notifier<Locale> {
  static const _prefsKey = 'app_locale';

  @override
  Locale build() {
    final code = ref.read(savedLocaleOnStartupProvider);
    final normalized = code == 'ar' ? 'ar' : 'en';
    AcceptLanguageHolder.value = normalized;
    return Locale(normalized);
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'ar' ? 'ar' : 'en';
    final next = Locale(code);
    state = next;
    AcceptLanguageHolder.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }
}
