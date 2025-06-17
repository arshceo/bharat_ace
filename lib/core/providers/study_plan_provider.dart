// // lib/core/providers/study_plan_provider.dart

// import 'dart:async'; // Import for Completer

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:bharat_ace/core/models/student_model.dart';
// import 'package:bharat_ace/core/models/study_task_model.dart';
// import 'package:bharat_ace/core/services/study_plan_service.dart';
// import 'student_details_provider.dart'; // Your existing provider

// // Provider for the StudyPlanService instance
// final studyPlanServiceProvider = Provider<StudyPlanService>((ref) {
//   // TODO: Replace the below placeholders with actual providers or values as needed
//   final syllabus = null; /* TODO: provide syllabus here */
//   final student = null;/* provide student here */
//   final overallStudentSubjectProgress = /* provide overallStudentSubjectProgress here */;
//   return StudyPlanService(
//     syllabus: syllabus,
//     student: student,
//     overallStudentSubjectProgress: overallStudentSubjectProgress,
//   );
// });

// // Provider to fetch TODAY's study tasks
// final dailyTaskProvider =
//     FutureProvider.autoDispose<List<StudyTask>>((ref) async {
//   print("[DailyTaskProvider] Attempting to fetch daily tasks.");

//   final AsyncValue<StudentModel?> studentDetailsAsync =
//       ref.watch(studentDetailsProvider);

//   return studentDetailsAsync.when(
//     data: (student) {
//       if (student == null) {
//         print(
//             "[DailyTaskProvider] Student data is null. Returning empty list.");
//         return Future.value([]);
//       }
//       if (student.id.isEmpty) {
//         print("[DailyTaskProvider] Student ID is empty. Returning empty list.");
//         return Future.value([]);
//       }
//       if (student.grade.isEmpty ||
//           student.board.isEmpty ||
//           student.enrolledSubjects.isEmpty) {
//         print(
//             "[DailyTaskProvider] Student profile incomplete (grade/board/subjects) for student ID: ${student.id}. Returning empty list.");
//         return Future.value([]);
//       }

//       final studyPlanService = ref.read(studyPlanServiceProvider);
//       print(
//           "[DailyTaskProvider] Fetching tasks for student ${student.id} (Grade: ${student.grade}, Board: ${student.board}, Subjects: ${student.enrolledSubjects})...");

//       return studyPlanService.getTodaysTasks(student).then((tasks) {
//         print(
//             "[DailyTaskProvider] Tasks fetched for student ${student.id}: ${tasks.length} task(s)");
//         return tasks;
//       }).catchError((error, stackTrace) {
//         print(
//             "[DailyTaskProvider] Error fetching tasks from service for student ${student.id}: $error");
//         print(stackTrace);
//         throw Exception("Failed to fetch tasks from service: $error");
//       });
//     },
//     loading: () {
//       print(
//           "[DailyTaskProvider] Student details are LOADING. Daily tasks are pending.");
//       // To ensure dailyTaskProvider remains in a loading state while studentDetailsProvider is loading,
//       // this branch must return a Future<List<StudyTask>> that doesn't complete.
//       // A Completer is the standard way to achieve this.
//       // The FutureProvider will re-evaluate when studentDetailsProvider resolves.
//       return Completer<List<StudyTask>>().future; // <--- CORRECTED LINE
//     },
//     error: (error, stackTrace) {
//       print("[DailyTaskProvider] Error in studentDetailsProvider: $error");
//       print(stackTrace);
//       throw Exception(
//           "Failed to load student details, cannot fetch tasks: $error");
//     },
//   );
// });
