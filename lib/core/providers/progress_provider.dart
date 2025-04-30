// lib/core/providers/progress_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/progress_models.dart';
import 'package:bharat_ace/core/services/progress_service.dart';
import 'student_details_provider.dart';

// Provider for the ProgressService instance
final progressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService();
});

// Provider family to get progress for a specific chapter for the current student
final chapterProgressProvider = FutureProvider.autoDispose
    .family<ChapterProgress, ({String subject, String chapterId})>(
        (ref, ids) async {
  final student = ref.watch(studentDetailsProvider);
  final String subject = ids.subject;
  final String chapterId = ids.chapterId;

  if (student == null || student.id.isEmpty) {
    throw Exception("Cannot fetch progress: User not logged in.");
  }
  if (subject.isEmpty || chapterId.isEmpty) {
    throw Exception("Subject and Chapter ID required to fetch progress.");
  }

  final progressService = ref.read(progressServiceProvider);
  print(
      "chapterProgressProvider($subject, $chapterId): Fetching progress for student ${student.id}");

  // Fetch progress - service now returns default ChapterProgress if not found
  return await progressService.getChapterProgress(
      student.id, subject, chapterId);
});
