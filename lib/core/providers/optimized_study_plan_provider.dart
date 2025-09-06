import 'package:bharat_ace/core/services/optimized_study_plan_service.dart';
import 'package:bharat_ace/core/models/study_task_model.dart';
import 'package:bharat_ace/core/providers/syllabus_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for optimized study plan service initialization
/// This keeps a single instance of the optimized service
final optimizedStudyPlanServiceProvider =
    Provider.autoDispose<OptimizedStudyPlanService?>((ref) {
  final syllabusAsync = ref.watch(syllabusProvider);
  final studentDetailsAsync = ref.watch(studentDetailsProvider);

  // Only create the service if we have both syllabus and student
  if (syllabusAsync.hasValue &&
      studentDetailsAsync.hasValue &&
      syllabusAsync.value != null &&
      studentDetailsAsync.value != null) {
    // Create the optimized service
    final service = OptimizedStudyPlanService(
      syllabus: syllabusAsync.value!,
      student: studentDetailsAsync.value!,
      overallStudentSubjectProgress: {}, // We'll use empty map for now as in original
    );

    // Start initialization in background without awaiting
    service.initialize();

    return service;
  }

  return null; // Return null if we don't have required data
});

/// Provider that watches the optimized service and triggers its initialization
/// when needed
final preloadStudyPlanProvider = FutureProvider.autoDispose<void>((ref) async {
  final service = ref.watch(optimizedStudyPlanServiceProvider);
  if (service != null) {
    await service.initialize();
  }
});

/// Provider for today's study tasks, using the optimized service when possible
final optimizedTodaysTasksProvider =
    FutureProvider<List<StudyTask>>((ref) async {
  // First, check for auth and student details
  final authUserAsync = ref.watch(authStateProvider);
  final studentDetailsAsync = ref.watch(studentDetailsProvider);
  final syllabusAsync = ref.watch(syllabusProvider);

  // Check for errors or loading states
  if (authUserAsync is AsyncLoading) {
    return [
      StudyTask(
          id: 'auth-loading',
          title: "Waiting for user session...",
          description: "",
          subject: "System",
          type: TaskType.config,
          estimatedTimeMinutes: 1,
          xpReward: 0)
    ];
  }

  if (authUserAsync is AsyncError ||
      !authUserAsync.hasValue ||
      authUserAsync.value == null) {
    return [
      StudyTask(
          id: 'auth-error',
          title: "Please log in to see your plan.",
          description: "",
          subject: "System",
          type: TaskType.config,
          estimatedTimeMinutes: 1,
          xpReward: 0)
    ];
  }

  // Handle missing syllabus or student details
  if (!syllabusAsync.hasValue ||
      !studentDetailsAsync.hasValue ||
      syllabusAsync.value == null ||
      studentDetailsAsync.value == null) {
    return [
      StudyTask(
          id: 'data-loading',
          title: "Loading your personalized plan...",
          description: "",
          subject: "System",
          type: TaskType.config,
          estimatedTimeMinutes: 1,
          xpReward: 0)
    ];
  }

  // Use the optimized service
  final service = ref.watch(optimizedStudyPlanServiceProvider);
  if (service != null) {
    if (!service.isReady) {
      // If service exists but isn't ready, trigger initialization
      ref.watch(preloadStudyPlanProvider);
    }

    // Use the optimized service's getTodaysTasks
    return service.getTodaysTasks();
  }

  // Fallback - create placeholder tasks
  return [
    StudyTask(
        id: 'service-error',
        title: "Setting up your study plan...",
        description: "This won't take long",
        subject: "System",
        type: TaskType.config,
        estimatedTimeMinutes: 1,
        xpReward: 0)
  ];
});
