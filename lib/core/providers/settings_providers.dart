// lib/core/providers/settings_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Re-define TargetLanguage enum here or import from a models file if it's shared
enum TargetLanguage { english, punjabiEnglish, hindi, hinglish }

final targetLanguageProvider =
    StateProvider<TargetLanguage>((ref) => TargetLanguage.english);

// You could also move other shared settings providers here, like:
// final currentFontFamilyProvider = StateProvider<String>((ref) => 'Roboto');
// final currentFontSizeMultiplierProvider = StateProvider<double>((ref) => 1.0);
