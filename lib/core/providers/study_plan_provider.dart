// lib/core/providers/study_plan_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/models/study_task_model.dart';
import 'package:bharat_ace/core/services/study_plan_service.dart';
import 'student_details_provider.dart'; // Your existing provider

// Provider for the StudyPlanService instance
final studyPlanServiceProvider = Provider<StudyPlanService>((ref) {
  return StudyPlanService();
});

// Provider to fetch TODAY's study task
final dailyTaskProvider =
    FutureProvider.autoDispose<List<StudyTask>>((ref) async {
  // Changed return type to List<StudyTask>
  final StudentModel? student = ref.watch(studentDetailsProvider);

  if (student == null) {
    print("dailyTaskProvider: No student data available.");
    // Return empty list instead of null if no student
    return [];
  }
  if (student.grade.isEmpty ||
      student.board.isEmpty ||
      student.enrolledSubjects.isEmpty) {
    print(
        "dailyTaskProvider: Student profile incomplete (grade/board/subjects).");
    // Return empty list if profile incomplete
    return [];
  }

  final studyPlanService = ref.read(studyPlanServiceProvider);

  print("dailyTaskProvider: Fetching tasks for student ${student.id}...");
  // Call the method that returns a list
  final List<StudyTask> tasks =
      await studyPlanService.getTodaysTasks(student); // Call getTodaysTasks
  print("dailyTaskProvider: Tasks fetched: ${tasks.length} task(s)");

  return tasks; // Return the list
});
