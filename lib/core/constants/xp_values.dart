// lib/core/constants/xp_values.dart

class XpValues {
  // Level Progression XP
  static const int prerequisiteLevelCompletion =
      25; // XP for completing prerequisites
  static const int regularLevelCompletion =
      50; // XP for completing a standard content level
  static const int advancedLevelCompletion =
      75; // XP for completing the 'advanced' or final level of a chapter
  static const int chapterMasteryBonus =
      100; // Extra bonus when the entire chapter is mastered

  // Engagement XP
  static const int askQuestion = 10;
  static const int addToKeyNotes = 5;

  // You can add more XP types here later (e.g., daily tasks, quizzes)
}
