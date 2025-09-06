// lib/core/providers/feature_toggle_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to track feature toggle state throughout the app
final featureToggleProvider =
    StateNotifierProvider<FeatureToggleNotifier, bool>((ref) {
  return FeatureToggleNotifier();
});

class FeatureToggleNotifier extends StateNotifier<bool> {
  static const String _storageKey = 'extra_features_enabled';

  /// Initialize with default value of false (features disabled)
  FeatureToggleNotifier() : super(false) {
    _loadSavedState();
  }

  /// Load saved state from shared preferences
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.getBool(_storageKey) ?? false;
    state = savedState;
  }

  /// Toggle feature state and save to shared preferences
  Future<void> toggleFeatures() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, state);
  }
}
