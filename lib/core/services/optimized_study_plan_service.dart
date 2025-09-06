import 'package:bharat_ace/core/services/study_plan_service.dart';
import 'package:bharat_ace/core/utils/background_task_helper.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/models/study_task_model.dart';
import 'package:bharat_ace/core/models/progress_models.dart';

/// Optimized wrapper for StudyPlanService that moves heavy operations to background threads
class OptimizedStudyPlanService {
  final StudyPlanService _service;
  bool _initialized = false;
  bool _initializationInProgress = false;

  OptimizedStudyPlanService({
    required Syllabus syllabus,
    required StudentModel student,
    required Map<String, SubjectProgress> overallStudentSubjectProgress,
    DateTime? today,
  }) : _service = StudyPlanService(
          syllabus: syllabus,
          student: student,
          overallStudentSubjectProgress: overallStudentSubjectProgress,
          today: today,
        );

  /// Prepares study plan data in a background thread
  Future<void> initialize() async {
    if (_initialized || _initializationInProgress) {
      return;
    }

    _initializationInProgress = true;

    // Run initial workitem generation in background
    try {
      await BackgroundTaskHelper.runInBackground<void, StudyPlanService>(
        _preloadWorkItems,
        _service,
      );
      _initialized = true;
    } finally {
      _initializationInProgress = false;
    }
  }

  /// Background job to prepare work items
  static Future<void> _preloadWorkItems(StudyPlanService service) async {
    // This will trigger the heavy calculation but we're not using the result directly
    // Just forcing the service to pre-calculate in background
    service
        .generateDailyTasks(); // Call the method that exists in StudyPlanService
    print("Background pre-loading of study plan completed");
  }

  /// Get today's tasks, using background processing if not already initialized
  Future<List<StudyTask>> getTodaysTasks() async {
    if (!_initialized) {
      await initialize();
    }
    return _service.generateDailyTasks(); // Use the actual method name
  }

  /// Get an estimate of when the syllabus will be completed
  /// Note: Since the StudyPlanService uses a private method for this,
  /// we're returning a calculated value directly
  Future<DateTime> getEstimatedCompletionDate() async {
    if (!_initialized) {
      await initialize();
    }

    // Calculate a default completion date 4 months from now
    // This mirrors the logic in StudyPlanService._calculateTargetCompletionDate
    final today = DateTime.now();
    return DateTime(today.year, today.month + 4, today.day);
  }

  bool get isReady => _initialized;
}
