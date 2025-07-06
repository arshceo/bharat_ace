// lib/core/services/initialization_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class InitializationService {
  static bool _supabaseInitialized = false;

  static bool get isSupabaseInitialized => _supabaseInitialized;

  static void markSupabaseInitialized() {
    _supabaseInitialized = true;
  }

  static void ensureSupabaseInitialized() {
    if (!_supabaseInitialized) {
      throw Exception(
          'Supabase is not initialized yet. Please wait for app startup to complete.');
    }
  }
}
