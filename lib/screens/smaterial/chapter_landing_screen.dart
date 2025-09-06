// lib/screens/smaterial/chapter_landing_screen.dart

// import 'package:bharat_ace/screens/alarm_screen.dart' as AppColors;
import 'package:bharat_ace/core/models/study_task_model.dart';
import 'package:bharat_ace/core/providers/personalized_study_plan_provider.dart'
    hide todaysPersonalizedTasksProvider; // Hide the original provider
import 'package:bharat_ace/core/providers/optimized_study_plan_provider.dart';
import 'package:bharat_ace/screens/smaterial/cat_teacher_classroom_screen.dart';
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
// import 'cat_teacher_classroom_screen.dart';

// Assuming AppColors is defined as in the previous SyllabusScreen example
// If not, define it here or import from your theme file.
// class AppColors { ... }

class ChapterLandingScreen extends ConsumerWidget {
  final String subjectName;
  final String chapterId;

  const ChapterLandingScreen(
      {super.key, required this.subjectName, required this.chapterId});

  // Show learning method selection dialog
  void _showLearningMethodDialog(BuildContext context,
      ChapterDetailed chapterData, ChapterProgress progress) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose
      builder: (BuildContext dialogContext) {
        return Dialog(
            backgroundColor: AppColors.cardBackground,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
                maxWidth: MediaQuery.of(dialogContext).size.width * 0.85,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cardBackground,
                    AppColors.cardBackground.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: 28,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      "Choose Your Learning Style",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      "How would you like to learn about:\n\"${chapterData.chapterTitle}\"?",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Cat Teacher Option
                    _buildLearningOption(
                      context: dialogContext,
                      icon: Icons.pets,
                      title: "🐱 Learn with Professor Cat",
                      subtitle:
                          "Interactive classroom experience with AI teacher",
                      gradient: [Colors.orange.shade400, Colors.red.shade400],
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _navigateToCatTeacher(context, chapterData, progress);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Simple Chat Option
                    _buildLearningOption(
                      context: dialogContext,
                      icon: Icons.chat_bubble_rounded,
                      title: "📖 Traditional Learning",
                      subtitle: "Standard content with Q&A chat support",
                      gradient: [
                        AppColors.primaryAccent,
                        AppColors.secondaryAccent
                      ],
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _navigateToTraditionalLearning(
                            context, chapterData, progress);
                      },
                    ),
                  ],
                ),
              ),
            ));
      },
    );
  }

  Widget _buildLearningOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient.map((c) => c.withOpacity(0.1)).toList(),
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: gradient.first.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: gradient.first,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCatTeacher(BuildContext context, ChapterDetailed chapterData,
      ChapterProgress progress) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
            name: "/catTeacher/${chapterId}/${progress.currentLevel}"),
        builder: (_) => CatTeacherClassroomScreen(
          chapter: chapterId,
          topic: chapterData.chapterTitle,
          subject: subjectName,
          content:
              "Let's explore ${chapterData.chapterTitle} together! I'm Professor Cat, and I'll make this topic fun and easy to understand.",
        ),
      ),
    );
  }

  void _navigateToTraditionalLearning(BuildContext context,
      ChapterDetailed chapterData, ChapterProgress progress) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
            name: "/levelContent/${chapterId}/${progress.currentLevel}"),
        builder: (_) => level_content.LevelContentScreen(
          subject: subjectName,
          chapterId: chapterId,
          levelName: progress.currentLevel,
          chapterData: chapterData,
        ),
      ),
    );
  }

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
    // NEW: Watch today's assigned tasks using optimized provider
    final AsyncValue<List<StudyTask>> todaysTasksAsync =
        ref.watch(optimizedTodaysTasksProvider);

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
      assignedTaskCompleted = relevantTodaysTaskForThisChapter.isCompleted;

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

    // --- Navigation Logic - Show dialog instead of auto-navigation ---
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
      } else {
        // Show learning method selection dialog
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            _showLearningMethodDialog(context, chapterData, progress);
          }
        });
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
          "Preparing your learning options for '${chapterData.chapterTitle}'...\n\n🎓 Choose your preferred learning style!";
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
