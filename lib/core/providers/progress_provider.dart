// lib/core/providers/progress_provider.dart
import 'dart:async';

import 'package:bharat_ace/core/constants/xp_values.dart';
import 'package:bharat_ace/core/providers/xp_overlay_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/progress_models.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart'; // For ChapterDetailed
import 'package:bharat_ace/core/models/student_model.dart'; // Import StudentModel for type clarity
import 'package:bharat_ace/core/services/progress_service.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart'; // Provides AsyncValue<StudentModel?>
import 'package:bharat_ace/core/providers/syllabus_provider.dart'; // To get chapterData

// Provider for the ProgressService instance
final progressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService();
});

// Args for chapterProgressProvider family
typedef ChapterProgressArgs = ({String subject, String chapterId});

// OLD FutureProvider (still useful for one-time fetches if needed elsewhere)
final chapterProgressProvider = FutureProvider.autoDispose
    .family<ChapterProgress, ChapterProgressArgs>((ref, args) async {
  final AsyncValue<StudentModel?> studentAsync =
      ref.watch(studentDetailsProvider);

  return studentAsync.when(
    data: (student) async {
      final String subject = args.subject;
      final String chapterId = args.chapterId;

      if (student == null || student.id.isEmpty) {
        print(
            "chapterProgressProvider (FUTURE): Student null or ID empty in data case.");
        throw Exception(
            "Cannot fetch progress: User not logged in or student ID is missing.");
      }
      if (subject.isEmpty || chapterId.isEmpty) {
        throw Exception("Subject and Chapter ID required to fetch progress.");
      }

      final progressService = ref.read(progressServiceProvider);
      print(
          "chapterProgressProvider (FUTURE - Subject: $subject, Chapter: $chapterId): Fetching for student ${student.id}");

      final syllabus = await ref.watch(syllabusProvider.future);
      final chapterDataFromSyllabus =
          _findChapterData(syllabus, subject, chapterId);

      return await progressService.getChapterProgress(
          student.id, subject, chapterId, chapterDataFromSyllabus);
    },
    loading: () {
      print(
          "chapterProgressProvider (FUTURE): studentDetailsProvider is loading.");
      final completer = Completer<ChapterProgress>();
      return completer.future;
    },
    error: (err, stack) {
      print(
          "chapterProgressProvider (FUTURE): Error in studentDetailsProvider: $err");
      throw Exception("Error fetching student details for progress: $err");
    },
  );
});

// NEW: StreamProvider family to get real-time progress updates
final chapterProgressStreamProvider = StreamProvider.autoDispose
    .family<ChapterProgress, ChapterProgressArgs>((ref, args) {
  final AsyncValue<StudentModel?> studentAsyncValue =
      ref.watch(studentDetailsProvider);
  final String subject = args.subject;
  final String chapterId = args.chapterId;

  return studentAsyncValue.when(
    data: (student) {
      if (student == null || student.id.isEmpty) {
        print(
            "chapterProgressStreamProvider: Student is null or ID is empty (studentAsyncValue.data). Emitting error progress.");
        return Stream.value(ChapterProgress.defaultProgress(
            chapterId: chapterId,
            chapterData: null,
            isError: true,
            errMessage: "User not logged in or student data not available."));
      }
      if (subject.isEmpty || chapterId.isEmpty) {
        print(
            "chapterProgressStreamProvider: Subject or Chapter ID empty. Emitting error progress.");
        return Stream.value(ChapterProgress.defaultProgress(
            chapterId: chapterId,
            chapterData: null,
            isError: true,
            errMessage: "Subject and Chapter ID required."));
      }

      final syllabusAsyncValue = ref.watch(syllabusProvider);
      return syllabusAsyncValue.when(
        data: (syllabus) {
          final chapterDataFromSyllabus =
              _findChapterData(syllabus, subject, chapterId);
          print(
              "chapterProgressStreamProvider: Syllabus loaded. Subscribing to progress for ${student.id}, $subject, $chapterId");
          final progressService = ref.read(progressServiceProvider);
          return progressService.watchChapterProgress(
              student.id, subject, chapterId, chapterDataFromSyllabus);
        },
        loading: () {
          print(
              "chapterProgressStreamProvider: Syllabus loading for $subject/$chapterId. Student: ${student.id}. Emitting placeholder progress.");
          final progressService = ref.read(progressServiceProvider);
          return progressService.watchChapterProgress(
              student.id, subject, chapterId, null);
        },
        error: (err, stack) {
          print(
              "chapterProgressStreamProvider: Error loading syllabus for $subject/$chapterId. Student: ${student.id}. Emitting error progress. Error: $err");
          return Stream.value(ChapterProgress.defaultProgress(
              chapterId: chapterId,
              chapterData: null,
              isError: true,
              errMessage: "Syllabus error: ${err.toString()}"));
        },
      );
    },
    loading: () {
      print(
          "chapterProgressStreamProvider: Student details loading. Emitting placeholder default progress.");
      return Stream.value(ChapterProgress.defaultProgress(
          chapterId: chapterId,
          chapterData: null,
          isError: false,
          errMessage: "Loading student details..."));
    },
    error: (err, stack) {
      print(
          "chapterProgressStreamProvider: Error loading student details. Emitting error progress. Error: $err");
      return Stream.value(ChapterProgress.defaultProgress(
          chapterId: chapterId,
          chapterData: null,
          isError: true,
          errMessage: "Student details error: ${err.toString()}"));
    },
  );
});

ChapterDetailed? _findChapterData(
    Syllabus? syllabus, String subjectContextKey, String chapterId) {
  if (syllabus == null) {
    print("_findChapterData: Syllabus data is null.");
    return null;
  }

  ChapterDetailed? searchInChaptersList(
      List<ChapterDetailed> chapters, String idToFind) {
    try {
      final chapter = chapters.firstWhere((ch) => ch.chapterId == idToFind);
      return chapter.chapterId.isNotEmpty ? chapter : null;
    } catch (_) {
      return null;
    }
  }

  final mainSubjectData = syllabus.subjects[subjectContextKey];
  if (mainSubjectData != null) {
    ChapterDetailed? chapter =
        searchInChaptersList(mainSubjectData.chapters, chapterId);
    if (chapter != null) return chapter;

    if (mainSubjectData.subSubjects != null) {
      for (var subSubjectDetail in mainSubjectData.subSubjects!.values) {
        chapter = searchInChaptersList(subSubjectDetail.chapters, chapterId);
        if (chapter != null) return chapter;
      }
    }
  }

  for (var eachMainSubject in syllabus.subjects.values) {
    if (eachMainSubject.subSubjects != null &&
        eachMainSubject.subSubjects!.containsKey(subjectContextKey)) {
      final subSubjectData = eachMainSubject.subSubjects![subjectContextKey]!;
      ChapterDetailed? chapter =
          searchInChaptersList(subSubjectData.chapters, chapterId);
      if (chapter != null) return chapter;
      print(
          "_findChapterData: Chapter '$chapterId' NOT FOUND in specific sub-subject '$subjectContextKey'.");
      return null;
    }
  }

  print(
      "_findChapterData: Chapter ID '$chapterId' could NOT BE LOCATED for the given context '$subjectContextKey'.");
  return null;
}

class MainProgressNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  MainProgressNotifier(this._ref) : super(const AsyncValue.data(null));
  Future<void> updateLevelCompletion({
    required String studentId,
    required String subject,
    required String chapterId,
    required String levelNameCompleted,
    required List<String>
        allChapterLevels, // This is chapterData.levels.map((l)=>l.levelName).toList()
    required String
        chapterTitle, // Pass chapterTitle for better overlay message
    double? scoreForLevel,
  }) async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    if (studentId.isEmpty) {
      state = AsyncValue.error("Student ID is empty.", StackTrace.current);
      return;
    }

    String nextCurrentLevelToSet;
    bool chapterIsNowTrulyMastered = false;
    final String completedLevelLower = levelNameCompleted.toLowerCase();

    // This 'prereqsChecked' update here is fine. It ensures the flag is set
    // upon formal completion of the "Prerequisites" level.
    bool markPrereqsCheckedInDb = (completedLevelLower == 'prerequisites');

    if (completedLevelLower == 'prerequisites') {
      if (allChapterLevels.isNotEmpty) {
        // Try to find "Fundamentals" specifically, otherwise take the first actual content level
        String targetNextLevelName = "Fundamentals";
        final fundamentalsLevel = allChapterLevels.firstWhere(
            (lvl) => lvl.toLowerCase() == targetNextLevelName.toLowerCase(),
            orElse: () => '');
        nextCurrentLevelToSet = fundamentalsLevel.isNotEmpty
            ? fundamentalsLevel
            : allChapterLevels.first;
      } else {
        // This case means chapter had prerequisites but no subsequent content levels defined
        nextCurrentLevelToSet = "NoContentLevelsAfterPrerequisites";
      }
    } else {
      int completedLevelIndex = allChapterLevels
          .indexWhere((lvl) => lvl.toLowerCase() == completedLevelLower);
      if (completedLevelIndex != -1) {
        if (completedLevelLower ==
                'advanced' || // Assuming 'advanced' is the typical last level
            completedLevelIndex == allChapterLevels.length - 1) {
          chapterIsNowTrulyMastered = true;
          nextCurrentLevelToSet =
              "Mastered"; // Special status for fully completed chapter
        } else {
          nextCurrentLevelToSet = allChapterLevels[completedLevelIndex + 1];
        }
      } else {
        // Should not happen if allChapterLevels is correctly sourced from ChapterDetailed.levels
        print(
            "Error: Completed level '$levelNameCompleted' not found in chapter's level list.");
        nextCurrentLevelToSet = "ErrorInProgression";
      }
    }
    final Map<String, dynamic> updates = {
      'currentLevel': nextCurrentLevelToSet,
      'isMastered': chapterIsNowTrulyMastered,
      'completedLevels': FieldValue.arrayUnion([levelNameCompleted]),
      'lastAccessed':
          DateTime.now().toIso8601String(), // Update last access time
    };

    if (markPrereqsCheckedInDb) {
      updates['prereqsChecked'] = true;
    }

    if (scoreForLevel != null) {
      String safeLevelNameKey =
          levelNameCompleted.replaceAll(RegExp(r'[.$#[\]/]'), '_');
      updates['levelScores.$safeLevelNameKey'] = scoreForLevel;
    }
    try {
      final progressService = _ref.read(progressServiceProvider);
      await progressService.updateChapterProgress(
          studentId, subject, chapterId, updates);

      if (!mounted) return;
      _ref.invalidate(chapterProgressStreamProvider(
          (subject: subject, chapterId: chapterId)));

      // --- AWARD CHAPTER MASTERY XP & SHOW OVERLAY ---
      if (chapterIsNowTrulyMastered) {
        print(
            "MainProgressNotifier: Chapter '$chapterTitle' ($chapterId) mastered by $studentId! Awarding bonus XP.");

        // Award the bonus XP by calling StudentDetailsNotifier
        // No need to await if this is a background task and the AppBar will eventually update.
        // If you await, it makes the sequence more robust.
        await _ref
            .read(studentDetailsNotifierProvider.notifier)
            .addXp(XpValues.chapterMasteryBonus);

        // Show a specific overlay for chapter mastery
        if (mounted) {
          // Check mounted again before triggering UI from a potentially long async operation
          _ref.read(xpOverlayProvider.notifier).showOverlay(
                amount: XpValues.chapterMasteryBonus,
                message: "Chapter Mastered!",
                subMessage: "'$chapterTitle' - All Levels Cleared!",
              );
        }
      }
      // --- END CHAPTER MASTERY XP ---

      if (!mounted) return;
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      print("Error in MainProgressNotifier.updateLevelCompletion: $e\n$stack");
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markPrerequisitesAsChecked({
    required String studentId,
    required String subject,
    required String chapterId,
    required bool chapterHasPrerequisites, // <-- NEW PARAMETER
  }) async {
    if (!mounted) {
      print(
          "MainProgressNotifier: Not mounted, aborting markPrerequisitesAsChecked.");
      return;
    }
    state = const AsyncValue.loading();

    if (studentId.isEmpty) {
      const errorMsg = "Student ID is empty. Cannot mark prerequisites.";
      print("MainProgressNotifier: $errorMsg");
      if (mounted) {
        state = AsyncValue.error(errorMsg, StackTrace.current);
      }
      return;
    }

    String determinedNextLevel;

    if (chapterHasPrerequisites) {
      // If the chapter HAS prerequisites, and the user acknowledged them,
      // the next level IS "Prerequisites".
      determinedNextLevel = "Prerequisites";
    } else {
      // If the chapter does NOT have prerequisites (this path is likely taken by auto-proceed),
      // then the next level is the first actual content level (e.g., "Fundamentals").
      // We need to fetch chapterData to find the first content level.
      determinedNextLevel =
          "Fundamentals"; // Default if fetching chapter data fails or no levels
      try {
        final syllabus = await _ref.read(syllabusProvider.future);
        final chapterData = _findChapterData(syllabus, subject, chapterId);

        if (chapterData != null) {
          if (chapterData.levels.isNotEmpty) {
            determinedNextLevel = chapterData.levels.first.levelName;
          } else {
            // Chapter exists but has no defined content levels.
            // This might be an edge case or indicate incomplete chapter setup.
            print(
                "MainProgressNotifier: Chapter $chapterId has no defined content levels. Defaulting to $determinedNextLevel (or consider 'NoContentLevels').");
            determinedNextLevel =
                "NoContentLevels"; // Or handle as an error/special state
          }
        } else {
          print(
              "MainProgressNotifier: ChapterData not found for $subject/$chapterId when determining first level. Defaulting to $determinedNextLevel.");
        }
      } catch (e) {
        print(
            "MainProgressNotifier: Error fetching syllabus/chapterData for markPrerequisitesAsChecked (no-prereqs path): $e. Defaulting to $determinedNextLevel.");
      }
    }

    try {
      final progressService = _ref.read(progressServiceProvider);
      await progressService.updateChapterProgress(
        studentId,
        subject,
        chapterId,
        {
          'prereqsChecked':
              true, // Always true when this function is successfully called
          'currentLevel': determinedNextLevel,
          'lastAccessed': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) {
        print("MainProgressNotifier: Not mounted after progress update.");
        return;
      }

      // Invalidate the stream provider so listeners will refetch.
      _ref.invalidate(chapterProgressStreamProvider(
          (subject: subject, chapterId: chapterId)));

      if (!mounted) return;

      state = const AsyncValue.data(null);
      print(
          "MainProgressNotifier: Prerequisites status updated for $subject - $chapterId, currentLevel set to '$determinedNextLevel'.");
    } catch (e, stack) {
      print(
          "MainProgressNotifier: Error in markPrerequisitesAsChecked: $e\n$stack");
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }
}

final progressProvider =
    StateNotifierProvider.autoDispose<MainProgressNotifier, AsyncValue<void>>(
        (ref) {
  return MainProgressNotifier(ref);
});
