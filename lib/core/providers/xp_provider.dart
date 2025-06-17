// lib/core/providers/xp_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _xpStorageKey = 'total_user_xp';

// Provider to access the XpNotifier
final xpProvider = StateNotifierProvider<XpNotifier, int>((ref) {
  return XpNotifier();
});

class XpNotifier extends StateNotifier<int> {
  XpNotifier() : super(0) {
    _loadInitialXp();
  }

  late SharedPreferences _prefs;

  Future<void> _loadInitialXp() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs.getInt(_xpStorageKey) ?? 0;
  }

  Future<void> _saveXp() async {
    await _prefs.setInt(_xpStorageKey, state);
  }

  /// Adds XP points to the user's total.
  /// The UI layer is responsible for showing feedback (e.g., SnackBar).
  void addXp(int amount) {
    if (amount <= 0) return; // Do not add 0 or negative XP
    state = state + amount;
    _saveXp();
    print("XP Updated: $state (Added $amount)"); // For debugging
  }

  // Optional: A way to reset XP for testing
  Future<void> resetXp() async {
    state = 0;
    await _saveXp();
    print("XP Reset to 0");
  }

  int get currentXp => state;
}
