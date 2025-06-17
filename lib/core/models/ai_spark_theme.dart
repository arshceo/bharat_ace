// lib/core/models/ai_spark_theme.dart
import 'dart:math'; // Not strictly needed for this file now, but often useful for theme variations

enum AiSparkThemeType {
  sun,
  moon,
  galaxy, // (Assuming you might have a GalaxyThemeDisplay or will create one)
  atom, // (Placeholder for a future theme)
  rocket,
  brainWaves, // (Placeholder for a future theme)
  dnaStrand, // (Placeholder for a future theme)
  bookMagic,
  labBeaker, // (Placeholder for a future theme)
  doraExplorer,
  codeMatrix, // (Placeholder for a future theme)
  thinkingCap,
  // Add more themes as you create them
  // Example placeholders:
  // mountains,
  // oceanWaves,
  // abstractArt,
}

// Helper to get the theme for the day
AiSparkThemeType getDailyTheme() {
  // Using DateTime.now().day ensures a change each day if you have up to 31 themes.
  // Using dayOfYear provides more variation if you have many themes.
  // For simplicity with fewer than 31 themes, DateTime.now().day is fine.
  final dayOfMonth = DateTime.now().day;
  final themes = AiSparkThemeType.values;

  // Cycle through themes based on the day of the month
  // This ensures that if you have 12 themes, on the 13th day, theme 1 appears again.
  return themes[(dayOfMonth - 1) %
      themes.length]; // -1 because day is 1-31, index is 0-based
}
