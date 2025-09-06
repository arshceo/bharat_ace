// lib/core/models/subscription_plans_model.dart

enum SubscriptionPlan { free, simple, pro, premium }

class SubscriptionPlanModel {
  final SubscriptionPlan plan;
  final String planName;
  final double monthlyPrice;
  final double yearlyPrice;
  final int simplificationLimit;
  final int dailyQuizAttempts;
  final bool hasAdvancedAnalytics;
  final bool hasPersonalizedLearning;
  final bool hasOfflineAccess;
  final bool hasAITutor;
  final bool hasUnlimitedContent;
  final bool hasProgressTracking;
  final List<String> features;
  final String description;
  final String currency;

  const SubscriptionPlanModel({
    required this.plan,
    required this.planName,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.simplificationLimit,
    required this.dailyQuizAttempts,
    required this.hasAdvancedAnalytics,
    required this.hasPersonalizedLearning,
    required this.hasOfflineAccess,
    required this.hasAITutor,
    required this.hasUnlimitedContent,
    required this.hasProgressTracking,
    required this.features,
    required this.description,
    this.currency = '₹',
  });

  static const Map<SubscriptionPlan, SubscriptionPlanModel> plans = {
    SubscriptionPlan.free: SubscriptionPlanModel(
      plan: SubscriptionPlan.free,
      planName: 'Free',
      monthlyPrice: 0.0,
      yearlyPrice: 0.0,
      simplificationLimit: 2,
      dailyQuizAttempts: 3,
      hasAdvancedAnalytics: false,
      hasPersonalizedLearning: false,
      hasOfflineAccess: false,
      hasAITutor: false,
      hasUnlimitedContent: false,
      hasProgressTracking: true,
      description: 'Perfect for getting started with basic learning features',
      features: [
        '2 content simplifications per subject per day',
        '3 quiz attempts per day',
        'Basic progress tracking',
        'Limited study materials',
        'Community support',
      ],
    ),
    SubscriptionPlan.simple: SubscriptionPlanModel(
      plan: SubscriptionPlan.simple,
      planName: 'Simple',
      monthlyPrice: 99.0,
      yearlyPrice: 999.0,
      simplificationLimit: 10,
      dailyQuizAttempts: 10,
      hasAdvancedAnalytics: false,
      hasPersonalizedLearning: true,
      hasOfflineAccess: false,
      hasAITutor: false,
      hasUnlimitedContent: false,
      hasProgressTracking: true,
      description:
          'Great for students who need more practice and personalized learning',
      features: [
        '10 content simplifications per subject per day',
        '10 quiz attempts per day',
        'Personalized learning recommendations',
        'Extended study materials library',
        'Progress tracking with detailed insights',
        'Email support',
      ],
    ),
    SubscriptionPlan.pro: SubscriptionPlanModel(
      plan: SubscriptionPlan.pro,
      planName: 'Pro',
      monthlyPrice: 199.0,
      yearlyPrice: 1999.0,
      simplificationLimit: 25,
      dailyQuizAttempts: 25,
      hasAdvancedAnalytics: true,
      hasPersonalizedLearning: true,
      hasOfflineAccess: true,
      hasAITutor: true,
      hasUnlimitedContent: false,
      hasProgressTracking: true,
      description:
          'Perfect for serious learners who want AI assistance and offline access',
      features: [
        '25 content simplifications per subject per day',
        '25 quiz attempts per day',
        'AI-powered personal tutor',
        'Offline content download',
        'Advanced performance analytics',
        'Personalized study schedules',
        'Priority customer support',
        'Study reminders & notifications',
      ],
    ),
    SubscriptionPlan.premium: SubscriptionPlanModel(
      plan: SubscriptionPlan.premium,
      planName: 'Premium',
      monthlyPrice: 299.0,
      yearlyPrice: 2999.0,
      simplificationLimit: -1, // Unlimited
      dailyQuizAttempts: -1, // Unlimited
      hasAdvancedAnalytics: true,
      hasPersonalizedLearning: true,
      hasOfflineAccess: true,
      hasAITutor: true,
      hasUnlimitedContent: true,
      hasProgressTracking: true,
      description:
          'The ultimate learning experience with unlimited access to all features',
      features: [
        'Unlimited content simplifications',
        'Unlimited quiz attempts',
        'Advanced AI tutor with conversation',
        'Full offline library access',
        'Comprehensive analytics dashboard',
        'Custom learning paths creation',
        '24/7 priority support with live chat',
        'Early access to new features',
        'Study group collaboration tools',
        'Parent/teacher progress reports',
      ],
    ),
  };

  bool get isUnlimitedSimplification => simplificationLimit == -1;
  bool get isUnlimitedQuizzes => dailyQuizAttempts == -1;

  double get yearlyDiscount =>
      ((monthlyPrice * 12) - yearlyPrice) / (monthlyPrice * 12) * 100;

  String get formattedMonthlyPrice =>
      monthlyPrice == 0 ? 'Free' : '$currency${monthlyPrice.toInt()}/month';
  String get formattedYearlyPrice =>
      yearlyPrice == 0 ? 'Free' : '$currency${yearlyPrice.toInt()}/year';
}

class UserSubscriptionState {
  final SubscriptionPlan currentPlan;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final bool isActive;
  final Map<String, int> dailySimplificationUsage; // subject -> count
  final Map<String, int> dailyQuizUsage; // date -> count
  final DateTime lastUsageReset;

  const UserSubscriptionState({
    required this.currentPlan,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.isActive,
    required this.dailySimplificationUsage,
    required this.dailyQuizUsage,
    required this.lastUsageReset,
  });

  UserSubscriptionState copyWith({
    SubscriptionPlan? currentPlan,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    bool? isActive,
    Map<String, int>? dailySimplificationUsage,
    Map<String, int>? dailyQuizUsage,
    DateTime? lastUsageReset,
  }) {
    return UserSubscriptionState(
      currentPlan: currentPlan ?? this.currentPlan,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      isActive: isActive ?? this.isActive,
      dailySimplificationUsage:
          dailySimplificationUsage ?? this.dailySimplificationUsage,
      dailyQuizUsage: dailyQuizUsage ?? this.dailyQuizUsage,
      lastUsageReset: lastUsageReset ?? this.lastUsageReset,
    );
  }

  SubscriptionPlanModel get planDetails =>
      SubscriptionPlanModel.plans[currentPlan]!;

  bool canSimplifyContent(String subject) {
    if (planDetails.isUnlimitedSimplification) return true;

    final usage = dailySimplificationUsage[subject] ?? 0;
    return usage < planDetails.simplificationLimit;
  }

  int getRemainingSimplifications(String subject) {
    if (planDetails.isUnlimitedSimplification) return -1;

    final usage = dailySimplificationUsage[subject] ?? 0;
    return (planDetails.simplificationLimit - usage)
        .clamp(0, planDetails.simplificationLimit);
  }

  bool canTakeQuiz() {
    if (planDetails.isUnlimitedQuizzes) return true;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final usage = dailyQuizUsage[today] ?? 0;
    return usage < planDetails.dailyQuizAttempts;
  }

  int getRemainingQuizAttempts() {
    if (planDetails.isUnlimitedQuizzes) return -1;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final usage = dailyQuizUsage[today] ?? 0;
    return (planDetails.dailyQuizAttempts - usage)
        .clamp(0, planDetails.dailyQuizAttempts);
  }

  bool needsUsageReset() {
    final now = DateTime.now();
    final resetDate =
        DateTime(lastUsageReset.year, lastUsageReset.month, lastUsageReset.day);
    final currentDate = DateTime(now.year, now.month, now.day);
    return currentDate.isAfter(resetDate);
  }
}
