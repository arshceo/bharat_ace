// lib/screens/gifts_screen/models/student_progress_model.dart
class StudentProgress {
  final String studentId;
  final int currentXp;
  final int consistencyStreakDays;
  final Map<String, int> completedTestsPerGiftPath;
  final Set<String> claimedGiftIds;

  StudentProgress({
    required this.studentId,
    required this.currentXp,
    required this.consistencyStreakDays,
    required this.completedTestsPerGiftPath,
    required this.claimedGiftIds,
  });

  // CORRECTED CONSTRUCTOR:
  StudentProgress.initial(this.studentId)
      : currentXp = 0,
        consistencyStreakDays = 0,
        completedTestsPerGiftPath = {}, // Comma instead of semicolon
        claimedGiftIds = {}; // Initializer for claimedGiftIds

  int getCompletedTestsForGift(String giftId) {
    return completedTestsPerGiftPath[giftId] ?? 0;
  }

  bool isGiftClaimed(String giftId) {
    return claimedGiftIds.contains(giftId);
  }

  StudentProgress copyWith({
    int? currentXp,
    int? consistencyStreakDays,
    Map<String, int>? completedTestsPerGiftPath,
    Set<String>? claimedGiftIds,
  }) {
    return StudentProgress(
      studentId: studentId,
      currentXp: currentXp ?? this.currentXp,
      consistencyStreakDays:
          consistencyStreakDays ?? this.consistencyStreakDays,
      completedTestsPerGiftPath:
          completedTestsPerGiftPath ?? this.completedTestsPerGiftPath,
      claimedGiftIds: claimedGiftIds ?? this.claimedGiftIds,
    );
  }
}
