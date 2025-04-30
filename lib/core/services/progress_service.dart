// lib/core/services/progress_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharat_ace/core/models/progress_models.dart';

class ProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = "studentProgress";

  /// Fetches the progress for a SPECIFIC chapter. Returns default if not found.
  Future<ChapterProgress> getChapterProgress(
      String studentId, String subject, String chapterId) async {
    if (studentId.isEmpty || subject.isEmpty || chapterId.isEmpty) {
      throw ArgumentError(
          "Student ID, Subject, and Chapter ID cannot be empty.");
    }
    print(
        "ProgressService: Fetching progress for Student: $studentId, Subject: $subject, Chapter: $chapterId");
    try {
      final docSnap =
          await _db.collection(_collectionPath).doc(studentId).get();

      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        // Safely navigate the nested map structure
        final subjectData = data['progressData']?[subject];
        if (subjectData is Map && subjectData['chapters']?[chapterId] is Map) {
          final chapterData = subjectData['chapters'][chapterId];
          print("ProgressService: Found existing chapter progress.");
          return ChapterProgress.fromMap(
              chapterId, chapterData as Map<String, dynamic>);
        }
      }
      // If document, subject, or chapter progress doesn't exist, return default
      print(
          "ProgressService: No existing progress found for chapter $chapterId. Returning default.");
      return ChapterProgress(
          chapterId: chapterId, lastAccessed: Timestamp.now());
    } catch (e, stack) {
      print("❌ ProgressService Error fetching chapter progress: $e\n$stack");
      throw Exception(
          "Could not fetch chapter progress."); // Rethrow specific error
    }
  }

  /// Updates specific fields within a chapter's progress data.
  Future<void> updateChapterProgress(String studentId, String subject,
      String chapterId, Map<String, dynamic> updates) async {
    if (studentId.isEmpty || subject.isEmpty || chapterId.isEmpty) {
      throw ArgumentError(
          "Student ID, Subject, and Chapter ID cannot be empty for update.");
    }
    print(
        "ProgressService: Updating progress for Student: $studentId, Subject: $subject, Chapter: $chapterId with updates: $updates");

    final docRef = _db.collection(_collectionPath).doc(studentId);
    final chapterPath = 'progressData.$subject.chapters.$chapterId';

    // Ensure lastAccessed is updated
    final finalUpdates = {
      ...updates,
      'lastAccessed':
          FieldValue.serverTimestamp(), // Use server timestamp for consistency
    };

    // Build the nested map for merging
    final Map<String, dynamic> dataToMerge = {
      'progressData': {
        subject: {
          'chapters': {chapterId: finalUpdates}
        }
      }
    };

    try {
      // Use set with merge: true. Creates the document/nested maps if they don't exist.
      await docRef.set(dataToMerge, SetOptions(merge: true));
      print("✅ ProgressService: Chapter progress updated successfully.");
    } catch (e, stack) {
      print("❌ ProgressService Error updating chapter progress: $e\n$stack");
      throw Exception("Failed to update progress in database.");
    }
  }

  /// Convenience method to update level and prerequisite status.
  Future<void> updateChapterLevelAndPrereqs(String studentId, String subject,
      String chapterId, String newLevel, bool prereqsChecked) async {
    await updateChapterProgress(studentId, subject, chapterId, {
      'currentLevel': newLevel,
      'prereqsChecked': prereqsChecked,
      // Optionally store assessment score if needed
    });
  }

  // Add markTopicComplete later when needed
}
