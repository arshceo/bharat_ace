// lib/core/providers/theme_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to track theme mode throughout the app
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<bool> {
  static const String _storageKey = 'is_dark_mode';

  /// Initialize with default value of true (dark mode enabled)
  ThemeNotifier() : super(true) {
    _loadSavedTheme();
    // Force dark mode on first run
    _forceDarkMode();
  }

  /// Load saved theme from shared preferences
  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Always default to dark mode (true)
    final isDarkMode = prefs.getBool(_storageKey) ?? true;
    state = isDarkMode;
  }

  /// Force dark mode
  Future<void> _forceDarkMode() async {
    if (!state) {
      state = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, true);
    }
  }

  /// Toggle theme mode and save to shared preferences
  Future<void> toggleTheme() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, state);
  }
}
