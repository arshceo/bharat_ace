// lib/core/services/study_plan_service.dart
import 'dart:math';
import 'package:bharat_ace/core/providers/student_subject_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/models/study_task_model.dart';
import 'package:bharat_ace/core/models/progress_models.dart';
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/core/providers/syllabus_provider.dart';

// --- DEBUG FLAGS ---
const bool _enableDebugLogging = true; // SET TO true FOR DETAILED LOGS

void _log(String message) {
  if (_enableDebugLogging) {
    print("[StudyPlanService] $message");
  }
}

class _WorkItem {
  final String subjectProgressKey;
  final String subjectDisplayName;
  final String chapterId;
  final String chapterTitle;
  final String? levelId;
  final String? levelTitle;
  final String? topicId;
  final String? topicTitle;
  final int estimatedTime;
  final int originalOrderIndex;

  _WorkItem({
    required this.subjectProgressKey,
    required this.subjectDisplayName,
    required this.chapterId,
    required this.chapterTitle,
    this.levelId,
    this.levelTitle,
    this.topicId,
    this.topicTitle,
    required this.estimatedTime,
    required this.originalOrderIndex,
  });

  @override
  String toString() {
    return 'WorkItem(SubProgKey: $subjectProgressKey, SubDisplay: $subjectDisplayName, Ch: $chapterTitle, Lvl: $levelTitle, Top: $topicTitle, EstTime: $estimatedTime)';
  }
}

class StudyPlanService {
  final Syllabus syllabus;
  final StudentModel student;
  final Map<String, SubjectProgress> overallStudentSubjectProgress;
  final DateTime today;
  int _globalOrderIndex = 0;

  static const int _defaultTopicTimeMinutes = 20;
  static const int _defaultChapterTimeIfNoTopicsOrLevels = 45;
  static const int _defaultLevelTimeIfNoTopics = 30;

  StudyPlanService({
    required this.syllabus,
    required this.student,
    required this.overallStudentSubjectProgress,
    DateTime? today,
  }) : today = today ??
            DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day) {
    _log(
        "Planner Initialized. Today: $today. Student Exam Date: ${student.examDate}");
  }

  int _getEstimatedTimeForChapterSyllabus(ChapterDetailed chapterSyllab) {
    if (chapterSyllab.estimatedStudyTimeMinutes != null &&
        chapterSyllab.estimatedStudyTimeMinutes! > 0) {
      return chapterSyllab.estimatedStudyTimeMinutes!;
    }
    int totalLevelTime = 0;
    for (var level in chapterSyllab.levels) {
      if (level.topics.isNotEmpty) {
        for (var topic in level.topics) {
          totalLevelTime +=
              topic.estimatedStudyTimeMinutes ?? _defaultTopicTimeMinutes;
        }
      } else {
        totalLevelTime += _defaultLevelTimeIfNoTopics;
      }
    }
    return totalLevelTime > 0
        ? totalLevelTime
        : _defaultChapterTimeIfNoTopicsOrLevels;
  }

  void _addWorkItemsFromSubject(
    String progressLookupKey,
    SubjectDetailed subjectSyllabusData,
    List<_WorkItem> workItems, {
    bool considerMastery = true,
  }) {
    _log(
        "  _addWorkItemsFromSubject: Processing ProgressKey: '$progressLookupKey', Syllabus Subject ID: '${subjectSyllabusData.subjectId}' (Display Name for tasks will be '$progressLookupKey')");

    final subjectProgressData =
        overallStudentSubjectProgress[progressLookupKey];
    final Map<String, ChapterProgress>? chaptersProgressMap =
        subjectProgressData?.chapters;

    if (subjectProgressData == null) {
      _log(
          "    WARNING: No progress data object found in 'overallStudentSubjectProgress' for key '$progressLookupKey'. All content for '${subjectSyllabusData.subjectId}' will be considered PENDING if 'considerMastery' is true.");
    }
    if (chaptersProgressMap == null || chaptersProgressMap.isEmpty) {
      _log(
          "    INFO: No chapter-specific progress entries found for '$progressLookupKey'. All chapters from syllabus will be considered PENDING if 'considerMastery' is true and relevant chapters exist in syllabus.");
    }

    String subjectDisplayNameForTask = progressLookupKey;

    for (var chapterSyllab in subjectSyllabusData.chapters) {
      final chapterProg = chaptersProgressMap?[chapterSyllab.chapterId];
      bool isChapterMarkedMasteredInProg = chapterProg?.isMastered ?? false;

      _log(
          "    Chapter: '${chapterSyllab.chapterTitle}' (Syllabus ID: ${chapterSyllab.chapterId})");
      if (chapterProg == null) {
        _log(
            "      No progress data found for this chapter. Assuming NOT MASTERED and starting from syllabus beginning.");
      } else {
        _log(
            "      Progress Found: Mastered: $isChapterMarkedMasteredInProg, CurrentLevel: '${chapterProg.currentLevel}', PrereqsOK: ${chapterProg.prereqsChecked}, CompletedLevels: ${chapterProg.completedLevels.length}, MasteredTopics: ${chapterProg.masteredTopics.length}");
      }
      _log(
          "      Syllabus defines ${chapterSyllab.levels.length} levels for this chapter.");

      if (considerMastery && isChapterMarkedMasteredInProg) {
        _log(
            "      Skipping chapter '${chapterSyllab.chapterTitle}' as it's marked mastered in progress data.");
        continue;
      }

      String? currentLevelIdFromProgress = chapterProg?.currentLevel;
      List<String> completedLevelIdsFromProgress =
          chapterProg?.completedLevels ?? [];

      bool startFromSyllabusDefinedStart = currentLevelIdFromProgress == null ||
          currentLevelIdFromProgress.isEmpty ||
          currentLevelIdFromProgress.toLowerCase() == "mastered" ||
          (currentLevelIdFromProgress.toLowerCase() == "prerequisites" &&
              (chapterProg?.prereqsChecked ??
                  (chapterSyllab.prerequisites.isEmpty)));

      bool workAddedForThisChapterFromLevels = false;

      if (chapterSyllab.levels.isNotEmpty) {
        bool foundStudentCurrentLevelInSyllabus = false;
        for (var levelSyllab in chapterSyllab.levels) {
          _log("      Level from Syllabus: '${levelSyllab.levelName}'");
          if (!startFromSyllabusDefinedStart &&
              !foundStudentCurrentLevelInSyllabus &&
              levelSyllab.levelName != currentLevelIdFromProgress) {
            _log(
                "        Skipping syllabus level '${levelSyllab.levelName}', current progress level is '$currentLevelIdFromProgress'");
            continue;
          }
          foundStudentCurrentLevelInSyllabus = true;
          _log(
              "        Processing syllabus level '${levelSyllab.levelName}'. Is in completedLevels (from progress): ${completedLevelIdsFromProgress.contains(levelSyllab.levelName)}");

          if (completedLevelIdsFromProgress.contains(levelSyllab.levelName)) {
            _log(
                "        Skipping syllabus level '${levelSyllab.levelName}' as it's in completedLevels list from progress data.");
            continue;
          }

          if (levelSyllab.topics.isNotEmpty) {
            List<String> masteredTopicsInThisLevel =
                (chapterProg?.masteredTopics ?? []);
            for (var topicSyllab in levelSyllab.topics) {
              if (considerMastery &&
                  masteredTopicsInThisLevel.contains(topicSyllab.topicId)) {
                _log(
                    "          Skipping mastered topic '${topicSyllab.topicTitle}' (ID: ${topicSyllab.topicId})");
                continue;
              }
              _log(
                  "          ADDING WorkItem (Topic): '${topicSyllab.topicTitle}' for subject '$subjectDisplayNameForTask'");
              workItems.add(_WorkItem(
                subjectProgressKey: progressLookupKey,
                subjectDisplayName: subjectDisplayNameForTask,
                chapterId: chapterSyllab.chapterId,
                chapterTitle: chapterSyllab.chapterTitle,
                levelId: levelSyllab.levelName,
                levelTitle: levelSyllab.levelName,
                topicId: topicSyllab.topicId,
                topicTitle: topicSyllab.topicTitle,
                estimatedTime: topicSyllab.estimatedStudyTimeMinutes ??
                    _defaultTopicTimeMinutes,
                originalOrderIndex: _globalOrderIndex++,
              ));
              workAddedForThisChapterFromLevels = true;
            }
          } else {
            _log(
                "          Level '${levelSyllab.levelName}' has no topics in syllabus, ADDING WorkItem (Level as Unit) for subject '$subjectDisplayNameForTask'");
            workItems.add(_WorkItem(
              subjectProgressKey: progressLookupKey,
              subjectDisplayName: subjectDisplayNameForTask,
              chapterId: chapterSyllab.chapterId,
              chapterTitle: chapterSyllab.chapterTitle,
              levelId: levelSyllab.levelName,
              levelTitle: levelSyllab.levelName,
              estimatedTime: _defaultLevelTimeIfNoTopics,
              originalOrderIndex: _globalOrderIndex++,
            ));
            workAddedForThisChapterFromLevels = true;
          }
        }
      }

      if (!workAddedForThisChapterFromLevels &&
          !isChapterMarkedMasteredInProg) {
        _log(
            "      ADDING WorkItem (Chapter as Unit): ${chapterSyllab.chapterTitle} for subject '$subjectDisplayNameForTask' (Reason: No levels OR no work added from levels, and chapter not mastered).");
        workItems.add(_WorkItem(
          subjectProgressKey: progressLookupKey,
          subjectDisplayName: subjectDisplayNameForTask,
          chapterId: chapterSyllab.chapterId,
          chapterTitle: chapterSyllab.chapterTitle,
          estimatedTime: _getEstimatedTimeForChapterSyllabus(chapterSyllab),
          originalOrderIndex: _globalOrderIndex++,
        ));
      }
    }

    subjectSyllabusData.subSubjects
        ?.forEach((subSyllabusKeyFromSyllabus, subSubjectSyllabusData) {
      _log(
          "    Recursively calling _addWorkItemsFromSubject for Sub-Syllabus Key: '$subSyllabusKeyFromSyllabus'");
      _addWorkItemsFromSubject(
          subSyllabusKeyFromSyllabus, subSubjectSyllabusData, workItems,
          considerMastery: considerMastery);
    });
  }

  List<_WorkItem> _getAllWorkItems({bool considerMastery = true}) {
    _log("_getAllWorkItems called. considerMastery: $considerMastery");
    List<_WorkItem> workItems = [];
    _globalOrderIndex = 0;
    syllabus.subjects.forEach((mainSyllabusKey, mainSubjectSyllabusData) {
      _addWorkItemsFromSubject(
          mainSyllabusKey, mainSubjectSyllabusData, workItems,
          considerMastery: considerMastery);
    });
    workItems
        .sort((a, b) => a.originalOrderIndex.compareTo(b.originalOrderIndex));
    _log(
        "_getAllWorkItems finished. Total items generated: ${workItems.length}");
    return workItems;
  }

  List<StudyTask> generateDailyTasks() {
    _log("generateDailyTasks called.");
    if (student.examDate == null) {
      _log("  No exam date set. Returning 'Set Exam Date' task.");
      return [
        StudyTask(
            id: 'set-exam-date-task',
            title: "Set Your Exam Date",
            description: "Set exam date for a personalized plan.",
            subject: "Setup",
            type: TaskType.config,
            estimatedTimeMinutes: 5,
            xpReward: 0)
      ];
    }

    List<_WorkItem> allPendingWorkItems =
        _getAllWorkItems(considerMastery: true);
    _log(
        "  Total pending work items from _getAllWorkItems: ${allPendingWorkItems.length}");

    if (allPendingWorkItems.isEmpty) {
      _log(
          "  No pending work items based on mastery. Generating revision tasks or 'all done'.");
      final int daysToExamForRevision =
          student.examDate!.difference(today).inDays;
      if (daysToExamForRevision > 1) {
        return _generateRevisionTasks(targetDailyTime: (240).clamp(120, 240));
      } else {
        return [
          StudyTask(
              id: 'all-done-final-prep',
              title: "Final Preparations!",
              description: "Focus on quick revisions and stay calm.",
              subject: "Revision",
              type: TaskType.revision,
              estimatedTimeMinutes: 60,
              xpReward: 100)
        ];
      }
    }

    DateTime targetSyllabusCompletionDate = _calculateTargetCompletionDate();
    int estimatedTotalMinutesLeft =
        allPendingWorkItems.fold(0, (sum, item) => sum + item.estimatedTime);
    if (estimatedTotalMinutesLeft == 0 && allPendingWorkItems.isNotEmpty) {
      estimatedTotalMinutesLeft =
          allPendingWorkItems.length * _defaultTopicTimeMinutes;
      _log(
          "  Warning - all pending items had 0 estimated time. Using fallback. New EstTotalMinLeft: $estimatedTotalMinutesLeft");
    }

    int daysToTargetCompletion =
        targetSyllabusCompletionDate.difference(today).inDays.clamp(1, 730);
    int calculatedIdealDailyMinutes = (estimatedTotalMinutesLeft > 0)
        ? (estimatedTotalMinutesLeft / daysToTargetCompletion).ceil()
        : 240;
    int dynamicDailyStudyTime = calculatedIdealDailyMinutes.clamp(
        student.grade == "10" || student.grade == "12" ? 270 : 240,
        student.grade == "10" || student.grade == "12" ? 330 : 300);

    final int daysToExam = student.examDate!.difference(today).inDays;
    if (daysToExam < 30 &&
        daysToExam > 0 &&
        calculatedIdealDailyMinutes > dynamicDailyStudyTime) {
      dynamicDailyStudyTime =
          calculatedIdealDailyMinutes.clamp(dynamicDailyStudyTime, 360);
    }
    if (daysToExam < 7 && daysToExam > 0) {
      dynamicDailyStudyTime =
          calculatedIdealDailyMinutes.clamp(dynamicDailyStudyTime, 420);
    }
    if (daysToExam <= 0) {
      dynamicDailyStudyTime = 120;
    }
    _log(
        "  Pacing: EstTotalMinLeft: $estimatedTotalMinutesLeft, DaysToTarget: $daysToTargetCompletion, IdealDailyMin: $calculatedIdealDailyMinutes, DynamicDailyStudyTime: $dynamicDailyStudyTime, DaysToExam: $daysToExam");

    List<StudyTask> dailyTasks;
    bool preferRevision =
        today.isAfter(targetSyllabusCompletionDate) && daysToExam < 21;
    if (preferRevision) {
      _log("  Preferring revision tasks.");
      dailyTasks = _generateRevisionTasks(
          targetDailyTime: dynamicDailyStudyTime.clamp(180, 300));
    } else {
      _log("  Generating multi-subject completion tasks.");
      dailyTasks = _generateMultiSubjectCompletionTasks(allPendingWorkItems,
          totalDailyStudyTimeMinutes: dynamicDailyStudyTime,
          daysUntilExam: daysToExam);
    }

    // Fallback if primary logic generated no tasks but there was pending work
    if (dailyTasks.isEmpty && allPendingWorkItems.isNotEmpty) {
      _log(
          "    WARNING: No tasks generated by primary logic despite pending work. Adding first pending item as a fallback task.");
      _WorkItem fallbackItem = allPendingWorkItems.first;
      dailyTasks.add(StudyTask(
        id: 'fallback-task-${fallbackItem.subjectProgressKey.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}-${fallbackItem.chapterId}',
        title:
            "Continue: ${fallbackItem.subjectDisplayName} - ${fallbackItem.chapterTitle}",
        description:
            "Focus on: ${fallbackItem.topicTitle ?? fallbackItem.levelTitle ?? 'Chapter Overview'}",
        subject: fallbackItem.subjectDisplayName,
        chapter: fallbackItem.chapterId,
        topic: fallbackItem.topicId,
        level: fallbackItem.levelId,
        type: TaskType.studyChapter,
        estimatedTimeMinutes: fallbackItem.estimatedTime.clamp(30, 120),
        xpReward: (fallbackItem.estimatedTime.clamp(30, 120) / 10)
            .round()
            .clamp(10, 50),
        isCompleted: false,
        progress: 0.0,
      ));
    }
    return dailyTasks;
  }

  DateTime _calculateTargetCompletionDate() {
    const int initialCompletionMonths = 4;
    DateTime targetDate =
        DateTime(today.year, today.month + initialCompletionMonths, today.day);
    DateTime examDate = student.examDate!;
    Duration revisionPeriod = Duration(
        days: (student.grade == "10" || student.grade == "12") ? 30 : 21);
    DateTime earliestPossibleCompletion = today.add(const Duration(days: 15));

    if (examDate
        .subtract(revisionPeriod)
        .isBefore(earliestPossibleCompletion)) {
      targetDate = examDate.subtract(Duration(
          days: (student.grade == "10" || student.grade == "12") ? 10 : 7));
      if (targetDate.isBefore(earliestPossibleCompletion)) {
        targetDate = earliestPossibleCompletion;
      }
    } else if (examDate.isBefore(targetDate.add(revisionPeriod))) {
      targetDate = examDate.subtract(revisionPeriod);
    }
    if (targetDate.isBefore(today)) targetDate = today;
    _log("  Calculated Target Syllabus Completion Date: $targetDate");
    return targetDate;
  }

  List<StudyTask> _generateMultiSubjectCompletionTasks(
    List<_WorkItem> allPendingWorkItems, {
    required int totalDailyStudyTimeMinutes,
    required int daysUntilExam,
  }) {
    _log(
        "  _generateMultiSubjectCompletionTasks: Pending items: ${allPendingWorkItems.length}, Target daily time: $totalDailyStudyTimeMinutes, DaysUntilExam: $daysUntilExam");
    List<StudyTask> dailyTasks = [];
    if (allPendingWorkItems.isEmpty) return dailyTasks;

    Map<String, List<_WorkItem>> workBySubjectDisplay = {};
    for (var item in allPendingWorkItems) {
      workBySubjectDisplay
          .putIfAbsent(item.subjectDisplayName, () => [])
          .add(item);
    }

    List<String> activeSubjectDisplayNames = workBySubjectDisplay.keys.toList();
    activeSubjectDisplayNames.removeWhere(
        (displayName) => workBySubjectDisplay[displayName]!.isEmpty);

    _log(
        "    Active Subject Display Names for task generation: $activeSubjectDisplayNames");
    if (activeSubjectDisplayNames.isEmpty) {
      _log(
          "    No active subjects with pending work after grouping. Returning empty tasks.");
      return dailyTasks;
    }

    activeSubjectDisplayNames.shuffle(Random(today.day));

    int maxSubjectsToday =
        (totalDailyStudyTimeMinutes / 30).floor().clamp(1, 5);
    int numberOfSubjectsToCoverToday =
        min(activeSubjectDisplayNames.length, maxSubjectsToday);
    if (numberOfSubjectsToCoverToday == 0 &&
        activeSubjectDisplayNames.isNotEmpty) numberOfSubjectsToCoverToday = 1;

    int timePerSubjectSlot =
        (totalDailyStudyTimeMinutes / numberOfSubjectsToCoverToday)
            .floor()
            .clamp(30, 120);
    int actualTotalAllocatedTime = 0;

    _log(
        "    Number of subjects to cover today: $numberOfSubjectsToCoverToday (out of ${activeSubjectDisplayNames.length}), Initial time per slot: $timePerSubjectSlot");

    int subjectsCoveredCount = 0;
    for (String subjectDisplayName in activeSubjectDisplayNames) {
      if (subjectsCoveredCount >= numberOfSubjectsToCoverToday ||
          actualTotalAllocatedTime >= totalDailyStudyTimeMinutes) {
        _log(
            "    Met subject count limit or daily time quota. Stopping task generation for more subjects.");
        break;
      }

      List<_WorkItem> pendingWorkForThisSubject =
          workBySubjectDisplay[subjectDisplayName]!;
      if (pendingWorkForThisSubject.isEmpty) continue;
      _WorkItem firstItemForSubject = pendingWorkForThisSubject.first;

      int currentSlotMaxTime =
          (totalDailyStudyTimeMinutes - actualTotalAllocatedTime);
      int timeForThisTask = min(timePerSubjectSlot, currentSlotMaxTime);

      if (subjectsCoveredCount == numberOfSubjectsToCoverToday - 1 &&
          currentSlotMaxTime > timeForThisTask) {
        timeForThisTask = currentSlotMaxTime.clamp(30, 180);
      }
      timeForThisTask = timeForThisTask.clamp(25, 180);

      if (timeForThisTask < 25) {
        _log(
            "    Skipping subject '$subjectDisplayName', remaining slot time too small ($timeForThisTask mins) for a meaningful task if others are planned.");
        if (numberOfSubjectsToCoverToday > 1 || dailyTasks.isNotEmpty) continue;
      }

      String taskTitle =
          "Study ${firstItemForSubject.subjectDisplayName}: ${firstItemForSubject.chapterTitle}";
      String taskDescription = "Allocate ~${timeForThisTask} mins. "
          "Start with: ${firstItemForSubject.topicTitle ?? firstItemForSubject.levelTitle ?? 'Chapter Overview'} "
          "in '${firstItemForSubject.chapterTitle}'. Focus on completing this section/chapter.";

      _log(
          "    Creating task for '$subjectDisplayName': Start with '${firstItemForSubject.topicTitle ?? firstItemForSubject.levelTitle ?? 'Chapter Overview'}', Ch '${firstItemForSubject.chapterTitle}'. Slot time: $timeForThisTask mins.");

      dailyTasks.add(StudyTask(
        id: 'daily-task-${firstItemForSubject.subjectProgressKey.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}-${firstItemForSubject.chapterId}-${Random().nextInt(10000)}',
        title: taskTitle,
        description: taskDescription,
        subject: firstItemForSubject.subjectDisplayName,
        chapter: firstItemForSubject.chapterId,
        topic: firstItemForSubject.topicId,
        level: firstItemForSubject.levelId,
        type: TaskType.studyChapter,
        estimatedTimeMinutes: timeForThisTask,
        xpReward: (timeForThisTask / 10).round().clamp(10, 50),
        isCompleted: false,
        progress: 0.0,
      ));
      actualTotalAllocatedTime += timeForThisTask;
      subjectsCoveredCount++;
    }

    if (daysUntilExam <= 7 &&
        daysUntilExam > 0 &&
        dailyTasks.where((t) => t.type == TaskType.test).isEmpty &&
        (totalDailyStudyTimeMinutes - actualTotalAllocatedTime >= 45)) {
      _log("    Adding final mock test as exam is near.");
      dailyTasks.add(StudyTask(
          id: 'final-mock-test-${today.toIso8601String()}',
          title: "Final Mock Test",
          description: "Take a comprehensive mock test (approx. 60-90 mins).",
          subject: "Comprehensive",
          type: TaskType.test,
          estimatedTimeMinutes: min(
              90,
              (totalDailyStudyTimeMinutes - actualTotalAllocatedTime)
                  .clamp(60, 120)),
          xpReward: 150,
          isCompleted: false));
    }
    _log(
        "  _generateMultiSubjectCompletionTasks: Generated ${dailyTasks.length} tasks. Total time used: $actualTotalAllocatedTime / $totalDailyStudyTimeMinutes");
    return dailyTasks;
  }

  List<StudyTask> _generateRevisionTasks({required int targetDailyTime}) {
    _log("  _generateRevisionTasks called. Target time: $targetDailyTime");
    List<StudyTask> revisionTasks = [];
    List<_WorkItem> allWorkAvailable = _getAllWorkItems(considerMastery: false);
    if (allWorkAvailable.isEmpty) {
      _log("    No work items available for revision pool.");
      return [
        StudyTask(
            id: 'no-rev-content',
            title: "Syllabus Empty or Error",
            description: "No content found to revise.",
            subject: "General",
            type: TaskType.other,
            estimatedTimeMinutes: 5,
            xpReward: 0)
      ];
    }

    Map<String, List<_WorkItem>> workBySubjectDisplay = {};
    for (var item in allWorkAvailable) {
      workBySubjectDisplay
          .putIfAbsent(item.subjectDisplayName, () => [])
          .add(item);
    }

    List<String> subjectDisplayNamesForRevision =
        workBySubjectDisplay.keys.toList();
    if (subjectDisplayNamesForRevision.isEmpty) return revisionTasks;

    subjectDisplayNamesForRevision
        .shuffle(Random(today.day + DateTime.now().hour));

    int subjectsToTouchForRevision = (targetDailyTime / 60)
        .floor()
        .clamp(1, min(3, subjectDisplayNamesForRevision.length));
    double timePerRevisionSlot = (targetDailyTime / subjectsToTouchForRevision)
        .floorToDouble()
        .clamp(45.0, 120.0);
    int accumulatedTime = 0;

    for (int i = 0;
        i < subjectsToTouchForRevision &&
            i < subjectDisplayNamesForRevision.length;
        i++) {
      String subjectDisplayName = subjectDisplayNamesForRevision[i];
      if (accumulatedTime >= targetDailyTime - 30) break;

      List<_WorkItem> subjectItems = workBySubjectDisplay[subjectDisplayName]!;
      if (subjectItems.isEmpty) continue;

      subjectItems.shuffle(Random(DateTime.now().millisecond + i));
      _WorkItem itemToRevise = subjectItems.first;

      int revisionTimeForThisSlot = timePerRevisionSlot.round();
      if (accumulatedTime + revisionTimeForThisSlot > targetDailyTime) {
        revisionTimeForThisSlot =
            (targetDailyTime - accumulatedTime).clamp(30, 120);
      }
      if (revisionTimeForThisSlot < 30) continue;

      String title =
          "Revise ${itemToRevise.subjectDisplayName}: ${itemToRevise.chapterTitle}";
      String description =
          "Review key concepts in '${itemToRevise.chapterTitle}'.";
      if (itemToRevise.topicTitle != null)
        description += " Focus on '${itemToRevise.topicTitle}'.";
      else if (itemToRevise.levelTitle != null)
        description += " Revisit level '${itemToRevise.levelTitle}'.";

      _log(
          "    Adding revision task for '${itemToRevise.subjectDisplayName}': ${itemToRevise.chapterTitle}, Est time: $revisionTimeForThisSlot");
      revisionTasks.add(StudyTask(
        id: 'rev-slot-${itemToRevise.subjectProgressKey.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}-${itemToRevise.chapterId}-${Random().nextInt(10000)}',
        title: title,
        description: description,
        subject: itemToRevise.subjectDisplayName,
        chapter: itemToRevise.chapterId,
        topic: itemToRevise.topicId,
        level: itemToRevise.levelId,
        type: TaskType.revision,
        estimatedTimeMinutes: revisionTimeForThisSlot,
        xpReward: (revisionTimeForThisSlot / 15).round().clamp(10, 40),
      ));
      accumulatedTime += revisionTimeForThisSlot;
    }
    _log(
        "  _generateRevisionTasks: Generated ${revisionTasks.length} tasks. Total time used: $accumulatedTime / $targetDailyTime");
    if (revisionTasks.isEmpty && allWorkAvailable.isNotEmpty) {
      _log(
          "    WARNING: No revision tasks generated despite available work. Adding first item as a fallback revision task.");
      _WorkItem fallbackItem = allWorkAvailable.first;
      revisionTasks.add(StudyTask(
        id: 'fallback-revision-${fallbackItem.subjectProgressKey.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}-${fallbackItem.chapterId}',
        title:
            "Revise: ${fallbackItem.subjectDisplayName} - ${fallbackItem.chapterTitle}",
        description:
            "Review key concepts for ${fallbackItem.topicTitle ?? fallbackItem.levelTitle ?? 'Chapter Overview'}",
        subject: fallbackItem.subjectDisplayName,
        chapter: fallbackItem.chapterId,
        topic: fallbackItem.topicId,
        level: fallbackItem.levelId,
        type: TaskType.revision,
        estimatedTimeMinutes:
            (fallbackItem.estimatedTime * 0.6).round().clamp(30, 90),
        xpReward:
            ((fallbackItem.estimatedTime * 0.6).round().clamp(30, 90) / 10)
                .round()
                .clamp(10, 30),
      ));
    }
    return revisionTasks;
  }
}

// Provider for today's tasks
final todaysPersonalizedTasksProvider =
    FutureProvider<List<StudyTask>>((ref) async {
  void _providerLog(String message) {
    if (_enableDebugLogging) {
      print("[TodaysTasksProvider] $message");
    }
  }

  _providerLog("Provider invoked. Fetching dependencies.");

  final syllabusAsyncValue = ref.watch(syllabusProvider);
  final studentDetailsAsyncValue = ref.watch(studentDetailsProvider);
  final authUserAsyncValue = ref.watch(authStateProvider);

  if (authUserAsyncValue.isLoading ||
      studentDetailsAsyncValue.isLoading ||
      syllabusAsyncValue.isLoading) {
    _providerLog("  Dependencies loading. Returning loading task.");
    return [
      StudyTask(
          id: 'loading-dependencies',
          title: "Initializing plan...",
          description: "Please wait.",
          subject: "System",
          type: TaskType.config,
          estimatedTimeMinutes: 1,
          xpReward: 0)
    ];
  }

  final authUser = authUserAsyncValue.asData?.value;
  final student = studentDetailsAsyncValue.asData?.value;
  final syllabusData = syllabusAsyncValue.asData?.value;

  if (authUser == null) {
    _providerLog("  Auth user is null.");
    return [
      StudyTask(
          id: 'auth-error',
          title: "Please log in.",
          subject: "System",
          type: TaskType.config,
          estimatedTimeMinutes: 1,
          xpReward: 0)
    ];
  }
  if (student == null) {
    _providerLog("  Student data is null.");
    return [
      StudyTask(
          id: 'student-error',
          title: "Profile Error.",
          subject: "System",
          type: TaskType.config,
          estimatedTimeMinutes: 1,
          xpReward: 0)
    ];
  }
  if (syllabusData == null) {
    _providerLog("  Syllabus data is null.");
    return [
      StudyTask(
          id: 'syllabus-error',
          title: "Syllabus Error.",
          subject: "System",
          type: TaskType.config,
          estimatedTimeMinutes: 1,
          xpReward: 0)
    ];
  }
  _providerLog(
      "  Base dependencies loaded. Student: ${student.name}, Enrolled: ${student.enrolledSubjects}");

  Map<String, SubjectProgress> overallStudentProgressMap = {};
  Set<String> allRelevantProgressKeys = {};

  if (student.enrolledSubjects.isEmpty) {
    _providerLog(
        "  Student has no enrolled subjects listed in their profile. Planning for ALL subjects in syllabus.");
    syllabusData.subjects.forEach((mainSyllabusKey, mainSubjectSyllabusData) {
      allRelevantProgressKeys.add(mainSyllabusKey);
      mainSubjectSyllabusData.subSubjects?.forEach((subSyllabusKey, _) {
        allRelevantProgressKeys.add(subSyllabusKey);
      });
    });
  } else {
    for (String enrolledSubjectKey in student.enrolledSubjects) {
      if (syllabusData.subjects.containsKey(enrolledSubjectKey)) {
        allRelevantProgressKeys.add(enrolledSubjectKey);
        final mainSubjectSyllabusData =
            syllabusData.subjects[enrolledSubjectKey]!;
        mainSubjectSyllabusData.subSubjects
            ?.forEach((subSyllabusKeyFromSyllabus, _) {
          allRelevantProgressKeys.add(subSyllabusKeyFromSyllabus);
          _providerLog(
              "    Added sub-subject '$subSyllabusKeyFromSyllabus' under enrolled main subject '$enrolledSubjectKey'.");
        });
      } else {
        bool foundAsSub = false;
        syllabusData.subjects.forEach((mainKey, mainData) {
          if (mainData.subSubjects?.containsKey(enrolledSubjectKey) ?? false) {
            allRelevantProgressKeys.add(enrolledSubjectKey);
            _providerLog(
                "    Enrolled subject '$enrolledSubjectKey' identified as a sub-subject under '$mainKey'. Added for progress fetching.");
            foundAsSub = true;
          }
        });
        if (!foundAsSub) {
          _providerLog(
              "  Warning: Enrolled subject '$enrolledSubjectKey' not found as a top-level or known sub-subject key in syllabus.json. Assuming it's a direct progress key.");
          allRelevantProgressKeys.add(enrolledSubjectKey);
        }
      }
    }
  }

  _providerLog(
      "  Relevant progress keys for fetching: $allRelevantProgressKeys");
  if (allRelevantProgressKeys.isEmpty) {
    _providerLog(
        "  No relevant progress keys identified. Returning empty tasks.");
    return [];
  }

  List<Future<void>> progressFutures = [];
  for (String progressKey in allRelevantProgressKeys) {
    progressFutures.add(ref
        .watch(studentSubjectProgressProvider(progressKey).future)
        .then((progress) {
      overallStudentProgressMap[progressKey] = progress;
      _providerLog(
          "    Successfully fetched/defaulted progress for key '$progressKey'. Chapters in prog: ${progress.chapters.length}");
    }).catchError((e, s) {
      _providerLog(
          "    ERROR fetching progress for key '$progressKey': $e. Using default empty SubjectProgress.");
      overallStudentProgressMap[progressKey] = SubjectProgress(chapters: {});
    }));
  }

  try {
    await Future.wait(progressFutures);
    _providerLog("  All progress fetch futures completed.");
  } catch (e) {
    _providerLog("  Error during Future.wait for progress fetching: $e.");
  }

  _providerLog(
      "  === Detailed Overall Student Progress Map START (Size: ${overallStudentProgressMap.length}) ===");
  overallStudentProgressMap.forEach((key, subjectProgress) {
    _providerLog("  Progress For Key: '$key'");
    if (subjectProgress.chapters.isEmpty) {
      _providerLog("    No chapters in progress data for '$key'.");
    } else {
      _providerLog(
          "    Chapters for '$key' (${subjectProgress.chapters.length}):");
      subjectProgress.chapters.forEach((chapterId, chapterProg) {
        _providerLog(
            "      Ch ID: '$chapterId', CurrentLvl: '${chapterProg.currentLevel}', Mastered: ${chapterProg.isMastered}, PrereqsOK: ${chapterProg.prereqsChecked}, CompLvls: ${chapterProg.completedLevels.join(',')}, MasteredTopsCount: ${chapterProg.masteredTopics.length}");
      });
    }
  });
  _providerLog("  === Detailed Overall Student Progress Map END ===");

  final planner = StudyPlanService(
    syllabus: syllabusData,
    student: student,
    overallStudentSubjectProgress: overallStudentProgressMap,
  );
  final List<StudyTask> tasks = planner
      .generateDailyTasks(); // This now contains the fallback if its internal logic results in empty tasks but had pending work
  _providerLog("  Planner generated ${tasks.length} tasks.");
  tasks.forEach((task) => _providerLog(
      "    - Gen Task: ${task.subject} - ${task.title} (Est: ${task.estimatedTimeMinutes} min, Ch: ${task.chapter}, Topic: ${task.topic}, Lvl: ${task.level})"));

  // CORRECTED: Removed the out-of-scope reference to allPendingWorkItems here.
  // The fallback is now handled INSIDE planner.generateDailyTasks().
  if (tasks.isEmpty && allRelevantProgressKeys.isNotEmpty) {
    _providerLog(
        "  CRITICAL WARNING: No tasks generated by planner, BUT there were relevant subjects. Check planner logic and progress data interpretation if you expected tasks.");
  }
  return tasks;
});
