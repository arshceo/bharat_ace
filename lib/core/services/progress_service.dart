// lib/core/services/progress_service.dart
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharat_ace/core/models/progress_models.dart';

class ProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = "studentProgress";

  /// Fetches the progress for a SPECIFIC chapter. Returns default if not found.
  Future<ChapterProgress> getChapterProgress(
    String studentId,
    String subject,
    String chapterId,
    ChapterDetailed?
        chapterDataFromSyllabus, // <-- CHANGED: pass ChapterDetailed
  ) async {
    if (studentId.isEmpty || subject.isEmpty || chapterId.isEmpty) {
      throw ArgumentError(
          "Student ID, Subject, and Chapter ID cannot be empty.");
    }
    print(
        "ProgressService (getChapterProgress): Fetching for Student: $studentId, Subject: $subject, Chapter: $chapterId");
    try {
      final docSnap =
          await _db.collection(_collectionPath).doc(studentId).get();

      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        final subjectDataMap = data['progressData']?[subject];
        if (subjectDataMap is Map &&
            subjectDataMap['chapters']?[chapterId] is Map) {
          final chapterProgressMap = subjectDataMap['chapters'][chapterId];
          print(
              "ProgressService (getChapterProgress): Found existing chapter progress.");
          return ChapterProgress.fromMap(
              chapterId, chapterProgressMap as Map<String, dynamic>);
        }
      }
      print(
          "ProgressService (getChapterProgress): No existing progress. Returning default for chapter $chapterId.");
      // USE THE NEW DEFAULT FACTORY
      return ChapterProgress.defaultProgress(
        chapterId: chapterId,
        chapterData: chapterDataFromSyllabus,
      );
    } catch (e, stack) {
      print("❌ ProgressService Error fetching chapter progress: $e\n$stack");
      // Return default progress with error state
      return ChapterProgress.defaultProgress(
        chapterId: chapterId,
        chapterData: chapterDataFromSyllabus,
        isError: true,
        errMessage: e.toString(),
      );
    }
  }

  // NEW: Method to watch chapter progress as a stream
  Stream<ChapterProgress> watchChapterProgress(
    String studentId,
    String subject,
    String chapterId,
    ChapterDetailed? chapterDataFromSyllabus, // For default progress
  ) {
    if (studentId.isEmpty || subject.isEmpty || chapterId.isEmpty) {
      print("watchChapterProgress: Invalid arguments. Returning error stream.");
      return Stream.value(ChapterProgress.defaultProgress(
          chapterId: chapterId,
          chapterData: chapterDataFromSyllabus,
          isError: true,
          errMessage: "Student ID, Subject, or Chapter ID is empty."));
    }
    print(
        "ProgressService (watchChapterProgress): Setting up stream for Student: $studentId, Subject: $subject, Chapter: $chapterId");
    final docRef = _db.collection(_collectionPath).doc(studentId);

    return docRef.snapshots().map((docSnap) {
      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        // Safely navigate the nested map structure
        final subjectDataMap = data['progressData']?[subject];
        if (subjectDataMap is Map &&
            subjectDataMap['chapters']?[chapterId] is Map) {
          final chapterProgressMap = subjectDataMap['chapters'][chapterId];
          print(
              "ProgressService (watch stream): Snapshot has data for $chapterId.");
          return ChapterProgress.fromMap(
              chapterId, chapterProgressMap as Map<String, dynamic>);
        }
      }
      // If document, subject, or chapter progress doesn't exist, return default
      print(
          "ProgressService (watch stream): No data in snapshot for $chapterId. Returning default.");
      return ChapterProgress.defaultProgress(
        chapterId: chapterId,
        chapterData: chapterDataFromSyllabus,
      );
    }).handleError((error, stackTrace) {
      print(
          "❌ ProgressService Error in watchChapterProgress stream for $subject/$chapterId: $error\n$stackTrace");
      // Emit a ChapterProgress with error state
      return ChapterProgress.defaultProgress(
        chapterId: chapterId,
        chapterData: chapterDataFromSyllabus,
        isError: true,
        errMessage: error.toString(),
      );
    });
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
    // No direct path needed for individual fields if merging whole chapter object,
    // but good for clarity if you were updating single sub-fields with dot notation.
    // final chapterPath = 'progressData.$subject.chapters.$chapterId';

    // Ensure lastAccessed is updated, and also other fields like isMastered if they are part of ChapterProgress
    // and your `updates` map might not include them but they should be part of the object written.
    // However, `MainProgressNotifier` builds the `updates` map comprehensively.
    final finalUpdates = {
      ...updates,
      'lastAccessed': FieldValue.serverTimestamp(),
    };

    // Build the nested map for merging. This structure ensures that if `studentId`, `subject`,
    // or `chapters` map doesn't exist, Firestore creates them.
    final Map<String, dynamic> dataToMerge = {
      'progressData': {
        subject: {
          'chapters': {
            chapterId:
                finalUpdates // The updates map IS the chapter progress object content
          }
        }
      }
    };

    try {
      await docRef.set(dataToMerge, SetOptions(merge: true));
      print(
          "✅ ProgressService: Chapter progress updated successfully for $chapterId.");
    } catch (e, stack) {
      print(
          "❌ ProgressService Error updating chapter progress for $chapterId: $e\n$stack");
      throw Exception(
          "Failed to update progress in database for chapter $chapterId.");
    }
  }

  /// Convenience method to update level and prerequisite status.
  Future<void> updateChapterLevelAndPrereqs(String studentId, String subject,
      String chapterId, String newLevel, bool prereqsChecked) async {
    // This method should also handle setting `isMastered` if `newLevel` is "Mastered"
    bool isNowMastered = (newLevel.toLowerCase() == "mastered");
    await updateChapterProgress(studentId, subject, chapterId, {
      'currentLevel': newLevel,
      'prereqsChecked': prereqsChecked,
      'isMastered': isNowMastered, // Ensure this is updated too
      // 'completedLevels' and 'levelScores' might also be relevant here
      // depending on the exact flow.
    });
  }
}
