// core/providers/personalized_study_plan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/models/study_task_model.dart';
import 'package:bharat_ace/core/models/progress_models.dart'; // Your progress models
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/core/providers/syllabus_provider.dart';

class PersonalizedStudyPlanner {
  final Syllabus syllabus;
  final StudentModel student;
  // ✨ CHANGED: overallProgress is Map<String (subjectId), SubjectProgress>
  final Map<String, SubjectProgress> overallProgress;
  final DateTime today;
  int _globalOrderIndex = 0;

  // Default estimated times if not found in models
  static const int _defaultTopicTimeMinutes = 30;
  static const int _defaultChapterTimeMinutesIfNoTopics = 90;

  PersonalizedStudyPlanner({
    required this.syllabus,
    required this.student,
    required this.overallProgress,
    DateTime? today,
  }) : today = today ??
            DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day);

  // Helper to get estimated time for a chapter
  int _getEstimatedTimeForChapter(ChapterDetailed chapter) {
    if (chapter.levels.any((level) => level.topics.isNotEmpty)) {
      int totalTime = 0;
      for (var level in chapter.levels) {
        for (var topic in level.topics) {
          // ✨ Assuming Topic model *might* get an estimatedStudyTimeMinutes field later
          // For now, using default.
          totalTime +=
              (/* topic.estimatedStudyTimeMinutes ?? */ _defaultTopicTimeMinutes);
        }
      }
      return totalTime > 0 ? totalTime : _defaultChapterTimeMinutesIfNoTopics;
    }
    return _defaultChapterTimeMinutesIfNoTopics; // Default if no topics with time
  }

  void _addWorkItemsFromChapters(
    List<ChapterDetailed> chapters,
    String subjectKey, // The key for the main subject (e.g., "math")
    String subjectDisplayName, // The display name for the subject/sub-subject
    Map<String, ChapterProgress>?
        subjectChaptersProgress, // Progress for chapters within this subject/sub-subject
    List<_WorkItem> workItems, {
    bool considerMastery = true,
  }) {
    for (var chapter in chapters) {
      final chapterProgress = subjectChaptersProgress?[chapter.chapterId];

      if (!considerMastery ||
          (chapterProgress == null || !chapterProgress.isMastered)) {
        bool chapterHasSpecificTopics =
            chapter.levels.any((level) => level.topics.isNotEmpty);

        if (chapterHasSpecificTopics) {
          for (var level in chapter.levels) {
            for (var topic in level.topics) {
              // TODO: Add topic-level progress check if your ChapterProgress.masteredTopics is reliable
              // bool isTopicMastered = chapterProgress?.masteredTopics.contains(topic.topicId) ?? false;
              // if (considerMastery && isTopicMastered) continue;

              workItems.add(_WorkItem(
                subjectId: subjectKey, // Store the main subject key for context
                subjectName: subjectDisplayName,
                chapterId: chapter.chapterId,
                chapterTitle: chapter.chapterTitle,
                topicId: topic.topicId,
                topicTitle: topic.topicTitle,
                // ✨ Assuming Topic model *might* get an estimatedStudyTimeMinutes field later.
                // Using default for now.
                estimatedTime:
                    (/* topic.estimatedStudyTimeMinutes ?? */ _defaultTopicTimeMinutes),
                originalOrderIndex: _globalOrderIndex++,
              ));
            }
          }
        } else {
          // No topics, treat chapter as a single work item
          workItems.add(_WorkItem(
            subjectId: subjectKey,
            subjectName: subjectDisplayName,
            chapterId: chapter.chapterId,
            chapterTitle: chapter.chapterTitle,
            estimatedTime: _getEstimatedTimeForChapter(chapter),
            originalOrderIndex: _globalOrderIndex++,
          ));
        }
      }
    }
  }

  List<StudyTask> generateDailyTasks() {
    if (student.examDate == null) {
      return [
        StudyTask(
          id: 'set-exam-date-task',
          title: "Set Your Exam Date",
          description:
              "Please set your exam date in your profile to get a daily study plan.",
          subject: "Setup",
          chapter: "",
          type: TaskType.config,
          estimatedTimeMinutes: 5,
          xpReward: 0,
          isCompleted: false,
        )
      ];
    }

    List<StudyTask> dailyTasks = [];
    List<_WorkItem> allPendingWork = _getAllPendingWork();

    if (allPendingWork.isEmpty &&
        student.examDate!.isAfter(today.add(const Duration(days: 1)))) {
      return _generateRevisionTasks(targetDailyTime: 240);
    }

    const int initialCompletionMonths = 4;
    DateTime targetSyllabusCompletionDate =
        DateTime(today.year, today.month + initialCompletionMonths, today.day);
    DateTime examDate = student.examDate!;
    Duration revisionPeriod = const Duration(days: 30);

    if (examDate.isBefore(targetSyllabusCompletionDate.add(revisionPeriod))) {
      targetSyllabusCompletionDate = examDate.subtract(revisionPeriod);
      if (targetSyllabusCompletionDate.isBefore(today)) {
        targetSyllabusCompletionDate =
            examDate.subtract(const Duration(days: 7));
        if (targetSyllabusCompletionDate.isBefore(today)) {
          targetSyllabusCompletionDate = today;
        }
      }
    }

    if (today.isAfter(targetSyllabusCompletionDate) || allPendingWork.isEmpty) {
      dailyTasks.addAll(_generateRevisionTasks(targetDailyTime: 240));
    } else {
      int daysToCompleteSyllabus =
          targetSyllabusCompletionDate.difference(today).inDays;
      daysToCompleteSyllabus =
          daysToCompleteSyllabus <= 0 ? 1 : daysToCompleteSyllabus;

      double totalPendingTime = allPendingWork.fold(
          0, (sum, item) => sum + item.estimatedTime.toDouble());
      if (totalPendingTime <= 0 && allPendingWork.isNotEmpty) {
        totalPendingTime = allPendingWork.length *
            _defaultTopicTimeMinutes.toDouble(); // Avg time per item
      }

      double timePerDayTarget =
          (daysToCompleteSyllabus > 0 && totalPendingTime > 0)
              ? totalPendingTime / daysToCompleteSyllabus
              : 240.0;
      double dailyStudyTargetMinutes =
          (timePerDayTarget < 240.0 && timePerDayTarget > 0)
              ? timePerDayTarget
              : 240.0;

      if (examDate.difference(today).inDays < 30 &&
          examDate.difference(today).inDays > 0) {
        dailyStudyTargetMinutes = 240;
      }

      dailyStudyTargetMinutes = dailyStudyTargetMinutes.clamp(30.0, 300.0);

      int accumulatedTime = 0;
      for (var workItem in allPendingWork) {
        if (accumulatedTime + workItem.estimatedTime <=
            dailyStudyTargetMinutes) {
          dailyTasks.add(StudyTask(
            id: 'task-${workItem.subjectId}-${workItem.chapterId}-${workItem.topicId ?? workItem.chapterId}',
            title: workItem.topicId != null
                ? "Study: ${workItem.topicTitle} (${workItem.chapterTitle})"
                : "Study Chapter: ${workItem.chapterTitle}",
            description: workItem.topicId != null
                ? "Focus on the topic: ${workItem.topicTitle} from the chapter '${workItem.chapterTitle}'."
                : "Cover the contents of the chapter: '${workItem.chapterTitle}'.",
            subject: workItem.subjectName,
            chapter: workItem.chapterId,
            topic: workItem.topicId, // Pass topicId to StudyTask
            type: workItem.topicId != null
                ? TaskType.studyTopic
                : TaskType.studyChapter,
            estimatedTimeMinutes: workItem.estimatedTime,
            xpReward: (workItem.estimatedTime / 10).round().clamp(5, 50) * 5,
            progress: 0.0,
            isCompleted: false,
          ));
          accumulatedTime += workItem.estimatedTime;
        } else {
          break;
        }
      }
    }

    if (examDate.difference(today).inDays <= 7 &&
        examDate.isAfter(today) &&
        dailyTasks.where((t) => t.type == TaskType.test).isEmpty) {
      dailyTasks.add(StudyTask(
        id: 'final-mock-test-${today.toIso8601String()}',
        title: "Final Mock Test - ${student.studyGoal ?? 'General'}",
        description:
            "Take this comprehensive mock test to check your exam readiness.",
        subject: "Comprehensive",
        chapter: "",
        type: TaskType.test,
        estimatedTimeMinutes: 120,
        xpReward: 200,
        isCompleted: false,
      ));
    }

    if (dailyTasks.isEmpty &&
        allPendingWork.isNotEmpty &&
        !today.isAfter(targetSyllabusCompletionDate)) {
      final firstWorkItem = allPendingWork.first;
      dailyTasks.add(StudyTask(
        id: 'generic-task-${firstWorkItem.subjectId}-${firstWorkItem.chapterId}',
        title: "Continue: ${firstWorkItem.chapterTitle}",
        description:
            "Continue your studies with the chapter: '${firstWorkItem.chapterTitle}'.",
        subject: firstWorkItem.subjectName,
        chapter: firstWorkItem.chapterId,
        topic: firstWorkItem.topicId,
        type:
            TaskType.studyChapter, // or studyTopic if firstWorkItem is a topic
        estimatedTimeMinutes: firstWorkItem.estimatedTime,
        xpReward: (firstWorkItem.estimatedTime / 10).round().clamp(5, 50) * 5,
        progress: 0.0,
        isCompleted: false,
      ));
    }

    if (dailyTasks.isEmpty &&
        allPendingWork.isEmpty &&
        student.examDate!.isAfter(today.add(const Duration(days: 1)))) {
      dailyTasks.add(StudyTask(
        id: 'all-done-revise-prompt',
        title: "Syllabus Covered! Review Time!",
        description:
            "Great job! You've covered the syllabus. Let's start revising or take a comprehensive test.",
        subject: "Revision",
        chapter: "",
        type: TaskType.revision,
        estimatedTimeMinutes: 60,
        xpReward: 50,
        isCompleted: false,
      ));
    }
    return dailyTasks;
  }

  List<_WorkItem> _getAllPendingWork() {
    List<_WorkItem> pendingWork = [];
    _globalOrderIndex = 0;
    syllabus.subjects.forEach((subjectKey, subjectData) {
      // Use subjectData.subjectId as display name if no separate 'name' field. Adjust if you add one.
      String mainSubjectDisplayName =
          subjectData.subjectId; // Or subjectData.name if it exists
      Map<String, ChapterProgress>? mainSubjectChaptersProgress =
          overallProgress[subjectKey]?.chapters;

      _addWorkItemsFromChapters(subjectData.chapters, subjectKey,
          mainSubjectDisplayName, mainSubjectChaptersProgress, pendingWork);

      subjectData.subSubjects?.forEach((subKey, subSubjectData) {
        // Use subSubjectData.subjectId or subKey as display name.
        String subSubjectDisplayName =
            subSubjectData.subjectId; // Or subSubjectData.name
        // For sub-subjects, the progress might be nested or keyed differently.
        // Assuming overallProgress key for sub-subject is the subKey itself if it's unique,
        // or it might be part of the main subject's progress structure.
        // This part is complex and depends on how your `overallProgress` is structured for sub-subjects.
        // Let's assume for now subKey is a direct key in overallProgress for its chapters.
        Map<String, ChapterProgress>? subChaptersProgress =
            overallProgress[subKey]?.chapters;
        // If sub-subject progress is nested under main subject, adjust accordingly:
        // e.g. Map<String, ChapterProgress>? subChaptersProgress = overallProgress[subjectKey]?.subSubjectsProgress?[subKey]?.chapters;

        _addWorkItemsFromChapters(subSubjectData.chapters, subKey,
            subSubjectDisplayName, subChaptersProgress, pendingWork);
      });
    });
    pendingWork
        .sort((a, b) => a.originalOrderIndex.compareTo(b.originalOrderIndex));
    return pendingWork;
  }

  List<StudyTask> _generateRevisionTasks({required int targetDailyTime}) {
    List<StudyTask> revisionTasks = [];
    List<_WorkItem> allWork = []; // Get all items, mastered or not
    _globalOrderIndex = 0;

    syllabus.subjects.forEach((subjectKey, subjectData) {
      String mainSubjectDisplayName =
          subjectData.subjectId; // Or subjectData.name
      Map<String, ChapterProgress>? mainSubjectChaptersProgress =
          overallProgress[subjectKey]?.chapters;
      _addWorkItemsFromChapters(subjectData.chapters, subjectKey,
          mainSubjectDisplayName, mainSubjectChaptersProgress, allWork,
          considerMastery: false);

      subjectData.subSubjects?.forEach((subKey, subSubjectData) {
        String subSubjectDisplayName =
            subSubjectData.subjectId; // Or subSubjectData.name
        Map<String, ChapterProgress>? subChaptersProgress =
            overallProgress[subKey]?.chapters;
        _addWorkItemsFromChapters(subSubjectData.chapters, subKey,
            subSubjectDisplayName, subChaptersProgress, allWork,
            considerMastery: false);
      });
    });
    allWork
        .sort((a, b) => a.originalOrderIndex.compareTo(b.originalOrderIndex));

    int accumulatedTime = 0;
    int itemsToRevise = 0;

    for (var workItem in allWork) {
      if (itemsToRevise >= 3 && accumulatedTime + 90 > targetDailyTime) break;

      int revisionTimeForItem =
          (workItem.estimatedTime * 0.6).round().clamp(15, 120);

      if (accumulatedTime + revisionTimeForItem <= targetDailyTime) {
        revisionTasks.add(StudyTask(
          id: 'revision-${workItem.subjectId}-${workItem.chapterId}-${workItem.topicId ?? workItem.chapterId}',
          title: workItem.topicId != null
              ? "Revise: ${workItem.topicTitle} (${workItem.chapterTitle})"
              : "Revise Chapter: ${workItem.chapterTitle}",
          description:
              "Review key concepts for ${workItem.topicId != null ? workItem.topicTitle : workItem.chapterTitle}.",
          subject: workItem.subjectName,
          chapter: workItem.chapterId,
          topic: workItem.topicId,
          type: TaskType.revision,
          estimatedTimeMinutes: revisionTimeForItem,
          xpReward: (revisionTimeForItem / 10).round().clamp(5, 50) * 5,
          isCompleted: false,
        ));
        accumulatedTime += revisionTimeForItem;
        itemsToRevise++;
        if (itemsToRevise >= 5) break;
      } else {
        break;
      }
    }

    if (accumulatedTime + 90 <= targetDailyTime &&
        revisionTasks.where((t) => t.type == TaskType.test).isEmpty) {
      revisionTasks.add(StudyTask(
        id: 'revision-test-${today.toIso8601String()}',
        title: "Revision Test: Mixed Topics",
        description: "Test your understanding of recently revised topics.",
        subject: "Comprehensive",
        chapter: "",
        type: TaskType.test,
        estimatedTimeMinutes: 90,
        xpReward: 150,
        isCompleted: false,
      ));
    }

    if (revisionTasks.isEmpty && allWork.isNotEmpty) {
      final firstWorkItem = allWork.first;
      int revisionTime =
          (firstWorkItem.estimatedTime * 0.6).round().clamp(15, 120);
      revisionTasks.add(StudyTask(
        id: 'default-revision-${firstWorkItem.subjectId}-${firstWorkItem.chapterId}',
        title: "Revise: ${firstWorkItem.chapterTitle}",
        description:
            "Start your revision with the chapter: '${firstWorkItem.chapterTitle}'.",
        subject: firstWorkItem.subjectName,
        chapter: firstWorkItem.chapterId,
        topic: firstWorkItem.topicId,
        type: TaskType.revision,
        estimatedTimeMinutes: revisionTime,
        xpReward: (revisionTime / 10).round().clamp(5, 50) * 5,
        isCompleted: false,
      ));
    }
    return revisionTasks;
  }
}

class _WorkItem {
  final String subjectId;
  final String subjectName; // Display Name
  final String chapterId;
  final String chapterTitle;
  final String? topicId;
  final String? topicTitle;
  final int estimatedTime;
  final int originalOrderIndex;

  _WorkItem({
    required this.subjectId,
    required this.subjectName,
    required this.chapterId,
    required this.chapterTitle,
    this.topicId,
    this.topicTitle,
    required this.estimatedTime,
    required this.originalOrderIndex,
  });
}

final todaysPersonalizedTasksProvider =
    FutureProvider<List<StudyTask>>((ref) async {
  final syllabusAsync = ref.watch(syllabusProvider);
  final studentDetailsAsync = ref.watch(studentDetailsProvider);
  final authUserAsync = ref.watch(authStateProvider);

  if (authUserAsync is AsyncLoading) {
    return [
      StudyTask(
          id: 'auth-loading',
          title: "Waiting for user session...",
          description: "",
          subject: "System",
          type: TaskType.config,
          estimatedTimeMinutes: 1,
          xpReward: 0)
    ];
  }
  if (authUserAsync is AsyncError ||
      !authUserAsync.hasValue ||
      authUserAsync.value == null) {
    return [
      StudyTask(
          id: 'auth-error',
          title: "Please log in to see your plan.",
          description: "",
          subject: "System",
          type: TaskType.config,
          estimatedTimeMinutes: 1,
          xpReward: 0)
    ];
  }

  final syllabus = syllabusAsync.value;
  final student = studentDetailsAsync.value;

  if (student == null || syllabus == null) {
    return [/* ... loading/setup tasks ... */];
  }

  // --- CRITICAL: Fetching overallStudentProgress ---
  // This needs to be robustly implemented.
  // For now, an empty map to avoid crashing, but this will lead to incorrect planning.
  Map<String, SubjectProgress> overallStudentProgress = {};

  // Example of how you might populate it (INEFFICIENT if done directly here for many chapters)
  // You'd need a provider that aggregates this.
  if (syllabusAsync.hasValue && studentDetailsAsync.hasValue) {
    // final studentId = studentDetailsAsync.value!.id;
    // For each subjectKey in syllabus.subjects.keys:
    //   Fetch SubjectProgress for studentId and subjectKey
    //   Populate overallStudentProgress[subjectKey] = fetchedSubjectProgress;
    //   This fetchedSubjectProgress would contain the map of ChapterProgress for that subject.
    //
    // Example: For a subject "math"
    // final mathProgress = await ref.read(subjectStudentProgressProvider("math").future);
    // if (mathProgress != null) {
    //   overallStudentProgress["math"] = mathProgress;
    // }
    // Do this for all subjects the student is enrolled in.
    print(
        "WARNING: overallStudentProgress is using a placeholder. Implement actual progress fetching.");
  }
  // --- End CRITICAL Section ---

  final planner = PersonalizedStudyPlanner(
    syllabus: syllabus,
    student: student,
    overallProgress: overallStudentProgress,
  );
  return planner.generateDailyTasks();
});
