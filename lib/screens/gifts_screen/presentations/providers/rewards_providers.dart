import 'package:flutter_riverpod/flutter_riverpod.dart';
// Adjust import paths based on your project structure
import 'package:bharat_ace/screens/gifts_screen/models/gift_model.dart';
import 'package:bharat_ace/screens/gifts_screen/models/student_progress_model.dart';
import 'package:bharat_ace/screens/gifts_screen/repositories/rewards_repository.dart';

// --- Repository Provider ---
final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return RewardsRepository();
});

// --- Data Providers ---
// Provider to simulate getting the current student's class
// In a real app, this would come from user authentication data or profile
final currentStudentClassProvider = Provider<String>((ref) {
  // TODO: Replace with actual logic to get student's class based on logged-in user
  return '6'; // Example: Hardcoding for Class 6th for now
});

// availableGiftsProvider now needs the student's class
final availableGiftsProvider =
    FutureProvider.family<List<Gift>, String>((ref, studentClass) async {
  final repository = ref.watch(rewardsRepositoryProvider);
  return repository.fetchAvailableGifts(studentClass);
});

// Using StateNotifierProvider for student progress as it can change
final studentProgressProvider =
    StateNotifierProvider<StudentProgressNotifier, AsyncValue<StudentProgress>>(
        (ref) {
  final repository = ref.watch(rewardsRepositoryProvider);
  // TODO: Replace "current_student_id" with actual logic to get current student ID
  return StudentProgressNotifier(repository, "current_student_id");
});

class StudentProgressNotifier
    extends StateNotifier<AsyncValue<StudentProgress>> {
  final RewardsRepository _repository;
  final String _studentId;

  StudentProgressNotifier(this._repository, this._studentId)
      : super(const AsyncValue.loading()) {
    _fetchInitialProgress();
  }

  Future<void> _fetchInitialProgress() async {
    try {
      final progress = await _repository.fetchStudentProgress(_studentId);
      if (mounted) {
        state = AsyncValue.data(progress);
      }
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  Future<void> addXp(int amount) async {
    if (state.hasValue) {
      final currentProgress = state.value!;
      final updatedProgress = currentProgress.copyWith(
          currentXp: currentProgress.currentXp + amount);
      state = AsyncValue.data(updatedProgress);
      try {
        await _repository.updateStudentProgress(updatedProgress);
      } catch (e) {
        state = AsyncValue.data(currentProgress);
        print("Error updating XP: $e");
      }
    }
  }

  Future<void> incrementConsistency() async {
    if (state.hasValue) {
      final currentProgress = state.value!;
      final updatedProgress = currentProgress.copyWith(
          consistencyStreakDays: currentProgress.consistencyStreakDays + 1);
      state = AsyncValue.data(updatedProgress);
      try {
        await _repository.updateStudentProgress(updatedProgress);
      } catch (e) {
        state = AsyncValue.data(currentProgress);
        print("Error updating consistency: $e");
      }
    }
  }

  // Updated to accept total tests done for a gift
  Future<void> completeTestForGift(String giftId, int testsDoneCount) async {
    if (state.hasValue) {
      final currentProgress = state.value!;
      final newCompletedTests =
          Map<String, int>.from(currentProgress.completedTestsPerGiftPath);
      newCompletedTests[giftId] = testsDoneCount; // Set the count directly

      final updatedProgress = currentProgress.copyWith(
          completedTestsPerGiftPath: newCompletedTests);
      state = AsyncValue.data(updatedProgress);
      try {
        await _repository.updateStudentProgress(updatedProgress);
      } catch (e) {
        state = AsyncValue.data(currentProgress);
        print("Error updating test completion: $e");
      }
    }
  }

  Future<void> claimGift(String giftId) async {
    if (state.hasValue) {
      final currentProgress = state.value!;
      if (currentProgress.claimedGiftIds.contains(giftId)) {
        print("Gift $giftId already claimed.");
        return; // Already claimed, do nothing
      }

      final newClaimedGiftIds =
          Set<String>.from(currentProgress.claimedGiftIds);
      newClaimedGiftIds.add(giftId);

      // Optionally, you might want to deduct XP or reset some progress related to this gift
      // For example, if claiming a gift costs XP (not in your current design, but possible)
      // int newXp = currentProgress.currentXp - (costOfGift[giftId] ?? 0);

      final updatedProgress = currentProgress.copyWith(
        claimedGiftIds: newClaimedGiftIds,
        // currentXp: newXp, // If XP deduction is implemented
      );
      state = AsyncValue.data(updatedProgress); // Optimistic update

      try {
        await _repository
            .updateStudentProgress(updatedProgress); // Persist the change
        print("Gift $giftId claimed successfully.");
      } catch (e) {
        // Revert state on error
        state = AsyncValue.data(currentProgress.copyWith(
            claimedGiftIds: Set<String>.from(currentProgress
                .claimedGiftIds) // Ensure it's a new set for proper state update
            ));
        print("Error claiming gift $giftId: $e");
      }
    }
  }
}

// --- UI State Provider ---
final selectedGiftForUnveilingProvider = StateProvider<Gift?>((ref) => null);

// --- Derived State / Logic Providers ---
final isGiftUnlockedProvider = Provider.family<bool, Gift>((ref, gift) {
  final studentProgressAsync = ref.watch(studentProgressProvider);

  return studentProgressAsync.maybeWhen(
    data: (progress) {
      return progress.currentXp >= gift.xpRequired &&
          progress.consistencyStreakDays >= gift.consistencyDaysRequired &&
          progress.getCompletedTestsForGift(gift.id) >= gift.testsRequired;
    },
    orElse: () => false,
  );
});
