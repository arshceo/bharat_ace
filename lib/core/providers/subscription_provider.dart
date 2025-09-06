// lib/core/providers/subscription_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_plans_model.dart';

// Provider for the current user's subscription state
final userSubscriptionProvider =
    StateNotifierProvider<UserSubscriptionNotifier, UserSubscriptionState>(
  (ref) => UserSubscriptionNotifier(),
);

// Provider for subscription plans
final subscriptionPlansProvider =
    Provider<Map<SubscriptionPlan, SubscriptionPlanModel>>(
  (ref) => SubscriptionPlanModel.plans,
);

class UserSubscriptionNotifier extends StateNotifier<UserSubscriptionState> {
  UserSubscriptionNotifier()
      : super(UserSubscriptionState(
          currentPlan: SubscriptionPlan.free,
          isActive: true,
          dailySimplificationUsage: {},
          dailyQuizUsage: {},
          lastUsageReset: DateTime.now(),
        ));

  // Use a simplification
  bool useSimplification(String subject) {
    if (!state.canSimplifyContent(subject)) {
      return false;
    }

    // Reset usage if a new day
    _resetUsageIfNeeded();

    if (state.planDetails.isUnlimitedSimplification) {
      return true;
    }

    final newUsage = Map<String, int>.from(state.dailySimplificationUsage);
    newUsage[subject] = (newUsage[subject] ?? 0) + 1;

    state = state.copyWith(dailySimplificationUsage: newUsage);
    return true;
  }

  // Use a quiz attempt
  bool useQuizAttempt() {
    if (!state.canTakeQuiz()) {
      return false;
    }

    // Reset usage if a new day
    _resetUsageIfNeeded();

    if (state.planDetails.isUnlimitedQuizzes) {
      return true;
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    final newUsage = Map<String, int>.from(state.dailyQuizUsage);
    newUsage[today] = (newUsage[today] ?? 0) + 1;

    state = state.copyWith(dailyQuizUsage: newUsage);
    return true;
  }

  // Upgrade subscription
  void upgradeSubscription(SubscriptionPlan newPlan) {
    final now = DateTime.now();
    state = state.copyWith(
      currentPlan: newPlan,
      isActive: true,
      subscriptionStartDate: now,
      subscriptionEndDate:
          now.add(const Duration(days: 30)), // 30 days subscription
    );
  }

  // Reset daily usage if needed
  void _resetUsageIfNeeded() {
    if (state.needsUsageReset()) {
      state = state.copyWith(
        dailySimplificationUsage: {},
        dailyQuizUsage: {},
        lastUsageReset: DateTime.now(),
      );
    }
  }

  // Get remaining simplifications for a subject
  int getRemainingSimplifications(String subject) {
    _resetUsageIfNeeded();
    return state.getRemainingSimplifications(subject);
  }

  // Get remaining quiz attempts
  int getRemainingQuizAttempts() {
    _resetUsageIfNeeded();
    return state.getRemainingQuizAttempts();
  }

  // Check if user can simplify content
  bool canSimplifyContent(String subject) {
    _resetUsageIfNeeded();
    return state.canSimplifyContent(subject);
  }

  // Check if user can take quiz
  bool canTakeQuiz() {
    _resetUsageIfNeeded();
    return state.canTakeQuiz();
  }
}
