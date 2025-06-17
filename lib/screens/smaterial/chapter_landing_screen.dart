// lib/screens/smaterial/chapter_landing_screen.dart

// import 'package:bharat_ace/screens/alarm_screen.dart' as AppColors;
import 'package:bharat_ace/core/models/study_task_model.dart';
import 'package:bharat_ace/core/providers/personalized_study_plan_provider.dart';
import 'package:bharat_ace/screens/syllabus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/models/progress_models.dart';
import 'package:bharat_ace/core/providers/progress_provider.dart';
import 'package:bharat_ace/core/providers/syllabus_provider.dart';

import '../../core/theme/app_colors.dart';
import 'prerequisite_check_screen.dart';
import '../../features/level_content/screens/level_content_screen.dart'
    as level_content;

// Assuming AppColors is defined as in the previous SyllabusScreen example
// If not, define it here or import from your theme file.
// class AppColors { ... }

class ChapterLandingScreen extends ConsumerWidget {
  final String subjectName;
  final String chapterId;

  const ChapterLandingScreen(
      {super.key, required this.subjectName, required this.chapterId});

  // _findChapterDataLocal helper (logic remains unchanged)
  ChapterDetailed? _findChapterDataLocal(
      Syllabus? syllabus, String subjectKeyOrSubKey, String chapterId) {
    if (syllabus == null) {
      print("_findChapterData: Syllabus data is null.");
      return null;
    }
    print(
        "    _findChapterData: Searching for Subject/SubKey='$subjectKeyOrSubKey', ChapterID='$chapterId'");

    ChapterDetailed? foundChapter;
    // Helper function to search chapters list
    ChapterDetailed? searchChapters(
        List<ChapterDetailed> chapters, String idToFind) {
      try {
        final chapter = chapters.firstWhere((ch) => ch.chapterId == idToFind,
            orElse: () => ChapterDetailed.empty());
        return chapter.chapterId.isNotEmpty ? chapter : null;
      } catch (_) {
        return null;
      }
    }

    if (syllabus.subjects.containsKey(subjectKeyOrSubKey)) {
      final subjectData = syllabus.subjects[subjectKeyOrSubKey]!;
      foundChapter = searchChapters(subjectData.chapters, chapterId);
      if (foundChapter != null) return foundChapter;

      if (subjectData.subSubjects != null) {
        for (var subKey in subjectData.subSubjects!.keys) {
          if (foundChapter != null) break;
          final subData = subjectData.subSubjects![subKey]!;
          foundChapter = searchChapters(subData.chapters, chapterId);
          if (foundChapter != null) return foundChapter;
        }
      }
    }

    if (foundChapter == null) {
      for (var mainSubjectKey in syllabus.subjects.keys) {
        if (foundChapter != null) break;
        final subjectData = syllabus.subjects[mainSubjectKey]!;
        if (subjectData.subSubjects != null) {
          for (var subKey in subjectData.subSubjects!.keys) {
            if (foundChapter != null) break;
            final subData = subjectData.subSubjects![subKey]!;
            if (subKey == subjectName) {
              // Match with the passed subjectName if it's a sub-subject context
              foundChapter = searchChapters(subData.chapters, chapterId);
              if (foundChapter != null) {
                break;
              }
            }
          }
          if (foundChapter != null) break;
        }
      }
    }
    if (foundChapter == null && syllabus.subjects.containsKey(subjectName)) {
      final subjectData = syllabus.subjects[subjectName]!;
      foundChapter = searchChapters(subjectData.chapters, chapterId);
    }

    if (foundChapter == null) {
      // print("    _findChapterDataLocal: Chapter ID '$chapterId' NOT LOCATED within context '$subjectKeyOrSubKey' or globally after refined search.");
    }
    return foundChapter;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Syllabus> syllabusAsync = ref.watch(syllabusProvider);
    final AsyncValue<ChapterProgress> chapterProgressAsync = ref.watch(
        chapterProgressStreamProvider(
            (subject: subjectName, chapterId: chapterId)));
    // NEW: Watch today's assigned tasks
    final AsyncValue<List<StudyTask>> todaysTasksAsync =
        ref.watch(todaysPersonalizedTasksProvider);

    final TextTheme textTheme = Theme.of(context).textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );

    // --- Combined Loading State ---
    if (syllabusAsync is AsyncLoading ||
        (syllabusAsync.hasValue && chapterProgressAsync is AsyncLoading) ||
        todaysTasksAsync is AsyncLoading) {
      // Added todaysTasksAsync loading check
      return _buildLoadingScreen(
          context, textTheme, "Preparing your learning module...");
    }

    // --- Error States ---
    if (syllabusAsync is AsyncError) {
      return _buildErrorScreen(context, textTheme, "Syllabus Unavailable",
          "We couldn't load the syllabus. Error: ${syllabusAsync.error}");
    }
    final Syllabus syllabus = syllabusAsync.value!;

    if (chapterProgressAsync is AsyncError) {
      return _buildErrorScreen(context, textTheme, "Progress Check Failed",
          "We couldn't check your chapter progress. Error: ${chapterProgressAsync.error}");
    }
    if (!chapterProgressAsync.hasValue) {
      // Check if progress data is actually available
      return _buildLoadingScreen(
          context, textTheme, "Finalizing chapter details...");
    }
    final ChapterProgress progress = chapterProgressAsync.value!;

    if (todaysTasksAsync is AsyncError) {
      // Optionally, show a less intrusive error for tasks, or log it.
      // For now, we'll proceed but won't have task-specific messages.
      print(
          "ChapterLanding: Error loading today's tasks: ${todaysTasksAsync.error}");
      // You could show a small error indicator or log, rather than a full error screen
      // that might block chapter loading.
    }
    final List<StudyTask> todaysTasks = todaysTasksAsync.value ?? [];

    final ChapterDetailed? chapterData =
        _findChapterDataLocal(syllabus, subjectName, chapterId);

    if (chapterData == null) {
      print(
          "ChapterLandingScreen: Critical - ChapterData is null for $subjectName/$chapterId AFTER syllabus and progress have values.");
      return _buildErrorScreen(context, textTheme, "Chapter Not Found",
          "We couldn't find the details for this chapter (ID: $chapterId, Subject: $subjectName). It might be missing or an issue with the syllabus data.");
    }

    if (progress.isErrorState) {
      print(
          "ChapterLandingScreen: Progress data indicates an error: ${progress.errorMessage}");
      return _buildErrorScreen(context, textTheme, "Progress Error",
          "There was an issue loading your progress for '${chapterData.chapterTitle}'. Message: ${progress.errorMessage ?? 'Unknown error'}");
    }

    // --- Determine if this chapter is part of today's mission and its status ---
    StudyTask? relevantTodaysTaskForThisChapter;
    for (var task in todaysTasks) {
      // A task is relevant if its chapterId and subjectName match.
      // Also consider tasks that might be subject-wide but not chapter-specific,
      // though your current StudyTask model links tightly to 'chapter'.
      if (task.chapter == chapterId && task.subject == subjectName) {
        relevantTodaysTaskForThisChapter = task;
        break;
      }
    }

    bool isMissionForThisChapter = relevantTodaysTaskForThisChapter != null;
    bool assignedTaskCompleted = false;
    if (isMissionForThisChapter) {
      // The primary source of truth for task completion is the 'isCompleted' field of the StudyTask itself.
      assignedTaskCompleted = relevantTodaysTaskForThisChapter!.isCompleted;

      // As a fallback or secondary check, if the task is about completing the chapter
      // and the chapter is mastered, we can also consider the task completed.
      // This handles cases where the StudyTask's 'isCompleted' might not have been updated yet
      // but the chapter's overall progress shows mastery.
      if (!assignedTaskCompleted &&
          progress.isMastered &&
          (relevantTodaysTaskForThisChapter.type == 'studyChapter' ||
              relevantTodaysTaskForThisChapter.type == 'revision')) {
        // Assuming 'studyChapter' type
        assignedTaskCompleted = true;
      }
    }

    // --- Navigation Logic (remains the same) ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      print(
          "ChapterLanding: PostFrameCallback. currentLevel: ${progress.currentLevel}, prereqsChecked: ${progress.prereqsChecked}, chapterId: $chapterId, isMastered: ${progress.isMastered}");

      const nonContentStates = [
        "NoContentAvailable",
        "ErrorInProgression",
        "NoContentLevelsAfterPrerequisites",
        "LoadingStudent",
      ];
      if (nonContentStates.contains(progress.currentLevel)) {
        return; // UI below will handle message
      }

      bool shouldGoToPrereqs =
          !progress.prereqsChecked && chapterData.prerequisites.isNotEmpty;

      if (shouldGoToPrereqs) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                settings: RouteSettings(name: "/prerequisiteCheck/$chapterId"),
                builder: (_) => PrerequisiteCheckScreen(
                    subject: subjectName,
                    chapterId: chapterId,
                    chapterData: chapterData)));
      } else if (!progress.isMastered && progress.currentLevel != "Mastered") {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                settings: RouteSettings(
                    name: "/levelContent/$chapterId/${progress.currentLevel}"),
                builder: (_) => level_content.LevelContentScreen(
                    subject: subjectName,
                    chapterId: chapterId,
                    levelName: progress.currentLevel,
                    chapterData: chapterData)));
      } else if (progress.isMastered || progress.currentLevel == "Mastered") {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${chapterData.chapterTitle} - You've mastered it! ✨",
              style: TextStyle(color: AppColors.textPrimary)),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ));
      }
    });

    // --- Default UI: Status Message Update ---
    String statusMessage;
    if (progress.currentLevel == "NoContentAvailable") {
      statusMessage =
          "Content for '${chapterData.chapterTitle}' is currently unavailable.";
    } else if (progress.currentLevel == "ErrorInProgression" ||
        progress.currentLevel == "NoContentLevelsAfterPrerequisites") {
      statusMessage =
          "There was an issue preparing '${chapterData.chapterTitle}'.";
    } else if (isMissionForThisChapter && assignedTaskCompleted) {
      statusMessage =
          "'${chapterData.chapterTitle}' - Mission task completed! ✅";
    } else if (isMissionForThisChapter) {
      statusMessage =
          "🎯 Today's Mission: Focus on '${chapterData.chapterTitle}'!";
    } else if (progress.isMastered) {
      statusMessage =
          "Chapter '${chapterData.chapterTitle}' Mastered! Well done!";
    } else {
      statusMessage =
          "Getting '${chapterData.chapterTitle}' ready...\nNext up: ${progress.currentLevel}";
    }

    return _buildLoadingScreen(
      context,
      textTheme,
      statusMessage,
      chapterTitle: chapterData.chapterTitle,
      isMission: isMissionForThisChapter,
      isMissionCompleted: assignedTaskCompleted,
    );
  }

  // --- Helper UI Widgets ---
  Widget _buildLoadingScreen(
    BuildContext context,
    TextTheme textTheme,
    String message, {
    String? chapterTitle,
    bool isMission = false, // NEW
    bool isMissionCompleted = false, // NEW
  }) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(chapterTitle ?? "Loading Chapter",
            style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.secondaryAccent),
                  backgroundColor: AppColors.primaryAccent.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Hang Tight!",
                style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // --- Mission Status Indicator ---
              if (isMission) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: (isMissionCompleted
                              ? AppColors
                                  .completedGreen // Use your theme colors
                              : AppColors.accentCyan)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isMissionCompleted
                              ? AppColors.completedGreen
                              : AppColors.accentCyan)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          isMissionCompleted
                              ? Icons.check_circle_outline_rounded
                              : Icons.flag_circle_rounded,
                          color: isMissionCompleted
                              ? AppColors.completedGreen
                              : AppColors.accentCyan,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isMissionCompleted
                            ? "Mission Task Done!"
                            : "Today's Mission!",
                        style: textTheme.bodyMedium?.copyWith(
                            color: isMissionCompleted
                                ? AppColors.completedGreen
                                : AppColors.accentCyan,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // --- End Mission Status Indicator ---
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(
      BuildContext context, TextTheme textTheme, String title, String message) {
    // ... (your _buildErrorScreen logic remains unchanged)
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text("Error",
            style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.redFailure.withOpacity(0.2),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.redFailure.withOpacity(0.5))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: AppColors.redFailure, size: 60),
              const SizedBox(height: 20),
              Text(title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textSecondary, height: 1.4)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                label: const Text("Go Back"),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
