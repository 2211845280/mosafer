import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in [main] after reading [SharedPreferences].
final savedThemeModeOnStartupProvider = Provider<String>((ref) => 'dark');

final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);

class AppThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefsKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.read(savedThemeModeOnStartupProvider);
    return saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  Future<void> setDarkMode(bool enabled) async {
    await setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}
