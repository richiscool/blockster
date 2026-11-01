import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app-wide light/dark theme choice and persists it.
///
/// [MaterialApp] listens to [themeMode], so calling [toggle] switches
/// the whole app instantly.
abstract class ThemeController {
  static const String _key = 'blockster_theme_dark';

  /// Current theme mode. Defaults to light.
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  /// Loads the saved theme. Call once before [runApp].
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_key) ?? false;
      themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      themeMode.value = ThemeMode.light;
    }
  }

  /// Switches between light and dark mode and saves the choice.
  static Future<void> toggle() async {
    final goDark = themeMode.value != ThemeMode.dark;
    themeMode.value = goDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, goDark);
    } catch (_) {
      // Ignore persistence errors; the theme still changes for this session.
    }
  }
}