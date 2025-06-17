// lib/core/models/progress_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart'; // Import for ChapterDetailed

// Represents progress data for a single chapter
class ChapterProgress {
  final String chapterId;
  final String currentLevel;
  final bool prereqsChecked;
  final bool isMastered; // <-- ADDED
  final Map<String, double> levelScores;
  final List<String> completedLevels; // <-- ADDED
  final List<String> masteredTopics;
  final List<String> weakTopics;
  final Timestamp lastAccessed;
  final bool isErrorState; // For stream error reporting
  final String? errorMessage; // For stream error reporting

  ChapterProgress({
    required this.chapterId,
    this.currentLevel = "Prerequisites",
    this.prereqsChecked = false,
    this.isMastered = false, // <-- ADDED default
    this.levelScores = const {},
    this.completedLevels = const [], // <-- ADDED default
    this.masteredTopics = const [],
    this.weakTopics = const [],
    required this.lastAccessed,
    this.isErrorState = false,
    this.errorMessage,
  });

  // Factory to create from Firestore map
  factory ChapterProgress.fromMap(String id, Map<String, dynamic> map) {
    Map<String, double> scores = {};
    if (map['levelScores'] is Map) {
      (map['levelScores'] as Map).forEach((key, value) {
        if (value is num) {
          scores[key.toString()] = value.toDouble();
        }
      });
    }
    bool mastered = map['isMastered'] as bool? ?? false;
    if (!mastered && map['progressPercentage'] != null) {
      mastered = (map['progressPercentage'] as num? ?? 0.0) >= 1.0;
    }
    return ChapterProgress(
      chapterId: id,
      currentLevel: map['currentLevel'] as String? ?? 'Prerequisites',
      prereqsChecked: map['prereqsChecked'] as bool? ?? false,
      isMastered: mastered,
      levelScores: scores,
      completedLevels:
          List<String>.from(map['completedLevels'] as List<dynamic>? ?? []),
      masteredTopics:
          List<String>.from(map['masteredTopics'] as List<dynamic>? ?? []),
      weakTopics: List<String>.from(map['weakTopics'] as List<dynamic>? ?? []),
      lastAccessed: map['lastAccessed'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // NEW: Factory for default progress, using syllabus info
  factory ChapterProgress.defaultProgress({
    required String chapterId,
    ChapterDetailed? chapterData, // From syllabus
    bool isError = false,
    String? errMessage,
  }) {
    String initialLevel = "Fundamentals"; // Default if no specific info
    bool initialPrereqsChecked = true; // Assume checked if no prereqs

    if (chapterData != null) {
      if (chapterData.prerequisites.isNotEmpty) {
        initialLevel = "Prerequisites";
        initialPrereqsChecked = false;
      } else if (chapterData.levels.isNotEmpty) {
        initialLevel = chapterData
            .levels.first.levelName; // Start with the first actual level
      } else {
        // No prerequisites and no levels defined in syllabus for this chapter
        initialLevel = "NoContentAvailable"; // Or some other indicator
      }
    } else {
      // If chapterData is null (e.g., syllabus not loaded yet or error)
      // A generic default is needed. "Prerequisites" is a common starting point.
      initialLevel = "Prerequisites";
      initialPrereqsChecked =
          false; // Assume not checked if we default to "Prerequisites"
    }

    return ChapterProgress(
      chapterId: chapterId,
      currentLevel: initialLevel,
      prereqsChecked: initialPrereqsChecked,
      isMastered: false,
      levelScores: {},
      completedLevels: [],
      masteredTopics: [],
      weakTopics: [],
      lastAccessed: Timestamp.now(),
      isErrorState: isError,
      errorMessage: errMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentLevel': currentLevel,
      'prereqsChecked': prereqsChecked,
      'isMastered': isMastered, // <-- ADDED
      'levelScores': levelScores,
      'completedLevels': completedLevels, // <-- ADDED
      'masteredTopics': masteredTopics,
      'weakTopics': weakTopics,
      'lastAccessed': lastAccessed,
    };
  }

  ChapterProgress copyWith({
    String? currentLevel,
    bool? prereqsChecked,
    bool? isMastered, // <-- ADDED
    Map<String, double>? levelScores,
    List<String>? completedLevels, // <-- ADDED
    List<String>? masteredTopics,
    List<String>? weakTopics,
    Timestamp? lastAccessed,
    bool? isErrorState,
    String? errorMessage,
  }) {
    return ChapterProgress(
      chapterId: chapterId,
      currentLevel: currentLevel ?? this.currentLevel,
      prereqsChecked: prereqsChecked ?? this.prereqsChecked,
      isMastered: isMastered ?? this.isMastered, // <-- ADDED
      levelScores: levelScores ?? this.levelScores,
      completedLevels: completedLevels ?? this.completedLevels, // <-- ADDED
      masteredTopics: masteredTopics ?? this.masteredTopics,
      weakTopics: weakTopics ?? this.weakTopics,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isErrorState: isErrorState ?? this.isErrorState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ... (StudentProgressData and SubjectProgress can remain as they are for now)
// StudentProgressData and SubjectProgress models as you provided them
class StudentProgressData {
  final String studentId;
  final Map<String, SubjectProgress> subjectProgressMap;

  StudentProgressData(
      {required this.studentId, required this.subjectProgressMap});

  factory StudentProgressData.fromMap(String id, Map<String, dynamic>? data) {
    Map<String, SubjectProgress> progressMap = {};
    if (data != null && data['progressData'] is Map) {
      (data['progressData'] as Map).forEach((subjectKey, subjectValue) {
        if (subjectValue is Map<String, dynamic>) {
          progressMap[subjectKey.toString()] =
              SubjectProgress.fromMap(subjectValue);
        }
      });
    }
    return StudentProgressData(studentId: id, subjectProgressMap: progressMap);
  }
}

class SubjectProgress {
  final Map<String, ChapterProgress> chapters; // Key: chapterId
  final double?
      overallCompletion; // Optional: if you track this at the subject document level

  SubjectProgress({required this.chapters, this.overallCompletion});

  factory SubjectProgress.fromMap(Map<String, dynamic> map) {
    // map is the subject document's data
    Map<String, ChapterProgress> chapterMap = {};
    final chaptersField = map['chapters']
        as Map<String, dynamic>?; // Assuming 'chapters' is a map field

    if (chaptersField != null) {
      chaptersField.forEach((chapterId, chapterDataMap) {
        if (chapterDataMap is Map<String, dynamic>) {
          chapterMap[chapterId] =
              ChapterProgress.fromMap(chapterId, chapterDataMap);
        }
      });
    }
    return SubjectProgress(
      chapters: chapterMap,
      overallCompletion: (map['overallCompletion'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chapters': chapters.map((key, value) => MapEntry(key, value.toMap())),
      'overallCompletion': overallCompletion,
    };
  }
}
