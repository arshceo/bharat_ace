// lib/core/providers/syllabus_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/services/syllabus_service.dart';
import 'student_details_provider.dart'; // Provides studentDetailsProvider (AsyncValue<StudentModel?>)

// Provider for the SyllabusService
final syllabusServiceProvider = Provider<SyllabusService>((ref) {
  return SyllabusService();
});

// Provider to get the FULLY PARSED Syllabus object for the current student's class/board
final syllabusProvider = FutureProvider.autoDispose<Syllabus>((ref) async {
  // Watch the AsyncValue<StudentModel?> from studentDetailsProvider
  final AsyncValue<StudentModel?> studentAsync =
      ref.watch(studentDetailsProvider);

  // Use .when to handle the states of studentAsync
  return studentAsync.when(
    data: (student) async {
      // student is StudentModel?
      if (student == null || student.grade.isEmpty || student.board.isEmpty) {
        print(
            "syllabusProvider: Student profile incomplete (Grade/Board required) or student is null.");
        // What to do here?
        // Option 1: Throw an exception, syllabusProvider will be in an error state.
        throw Exception(
            "Student profile incomplete (Grade/Board required for syllabus) or user not fully loaded.");
        // Option 2: Return a default/empty Syllabus if appropriate for your app.
        // return Syllabus.empty(); // if you have such a constructor
      }
      final String className = student.grade;
      final String board = student.board; // Safe now due to check above

      print(
          "syllabusProvider: Fetching syllabus for Class: $className, Board: $board");
      final syllabusService = ref.read(syllabusServiceProvider);
      try {
        return await syllabusService.getClassSyllabusFromJson(className, board);
      } catch (e) {
        print("syllabusProvider: Error fetching syllabus from service: $e");
        throw Exception("Failed to load syllabus for $className - $board: $e");
      }
    },
    loading: () {
      print("syllabusProvider: Waiting for student details to load...");
      // Keep syllabusProvider in a loading state while student details are loading.
      // The FutureProvider will remain in loading state if its async function doesn't complete.
      // We achieve this by returning a future that won't complete.
      final completer = Completer<Syllabus>();
      return completer.future;
    },
    error: (err, stack) {
      print(
          "syllabusProvider: Error in studentDetailsProvider dependency: $err");
      throw Exception(
          "Cannot load syllabus due to student details error: $err");
    },
  );
});
