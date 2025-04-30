// lib/core/providers/syllabus_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart'; // Import detailed models
import 'package:bharat_ace/core/services/syllabus_service.dart'; // Import service
import 'student_details_provider.dart';

// Provider for the SyllabusService
final syllabusServiceProvider = Provider<SyllabusService>((ref) {
  return SyllabusService();
});

// Provider to get the FULLY PARSED Syllabus object for the current student's class/board
final syllabusProvider = FutureProvider.autoDispose<Syllabus>((ref) async {
  final StudentModel? student = ref.watch(studentDetailsProvider);

  if (student == null || student.grade.isEmpty || student.board.isEmpty) {
    throw Exception(
        "Student profile incomplete (Grade/Board required for syllabus).");
  }
  final String className = student.grade;
  final String board = student.board;

  final syllabusService = ref.read(syllabusServiceProvider);
  // Using JSON loading for now
  return await syllabusService.getClassSyllabusFromJson(className, board);
  // Or switch to Firestore later:
  // return await syllabusService.getClassSyllabusFromFirestore(className, board);
});
