// lib/core/models/progress_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Represents progress data for a single chapter
class ChapterProgress {
  final String chapterId;
  final String
      currentLevel; // e.g., "Prerequisites", "Fundamentals", "Mastered"
  final bool prereqsChecked;
  final Map<String, double> levelScores; // e.g., {"Fundamentals": 0.85}
  final List<String> masteredTopics; // Optional for finer tracking
  final List<String> weakTopics; // Optional for finer tracking
  final Timestamp lastAccessed;

  ChapterProgress({
    required this.chapterId,
    this.currentLevel = "Prerequisites", // Default starting point
    this.prereqsChecked = false,
    this.levelScores = const {},
    this.masteredTopics = const [],
    this.weakTopics = const [],
    required this.lastAccessed,
  });

  // Factory to create from Firestore map
  factory ChapterProgress.fromMap(String id, Map<String, dynamic> map) {
    // Convert levelScores map values which might be int or double in Firestore
    Map<String, double> scores = {};
    if (map['levelScores'] is Map) {
      (map['levelScores'] as Map).forEach((key, value) {
        if (value is num) {
          // Check if it's a number (int or double)
          scores[key.toString()] = value.toDouble();
        }
      });
    }

    return ChapterProgress(
      chapterId: id,
      currentLevel: map['currentLevel'] ?? 'Prerequisites',
      prereqsChecked: map['prereqsChecked'] ?? false,
      levelScores: scores,
      masteredTopics: List<String>.from(map['masteredTopics'] ?? []),
      weakTopics: List<String>.from(map['weakTopics'] ?? []),
      lastAccessed:
          map['lastAccessed'] ?? Timestamp.now(), // Default if missing
    );
  }

  // Method to convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      // chapterId is the document key, not stored inside usually
      'currentLevel': currentLevel,
      'prereqsChecked': prereqsChecked,
      'levelScores': levelScores,
      'masteredTopics': masteredTopics,
      'weakTopics': weakTopics,
      'lastAccessed': lastAccessed, // Or FieldValue.serverTimestamp() on write
    };
  }

  // Optional: copyWith method for easier state updates
  ChapterProgress copyWith({
    String? currentLevel,
    bool? prereqsChecked,
    Map<String, double>? levelScores,
    List<String>? masteredTopics,
    List<String>? weakTopics,
    Timestamp? lastAccessed,
  }) {
    return ChapterProgress(
      chapterId: chapterId, // Keep original ID
      currentLevel: currentLevel ?? this.currentLevel,
      prereqsChecked: prereqsChecked ?? this.prereqsChecked,
      levelScores: levelScores ?? this.levelScores,
      masteredTopics: masteredTopics ?? this.masteredTopics,
      weakTopics: weakTopics ?? this.weakTopics,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }
}

// Represents the overall progress structure for a student (matches Firestore doc)
class StudentProgressData {
  final String studentId;
  // Map where key is Subject Name (e.g., "Science"), value is SubjectProgress
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

// Represents progress within a specific subject
class SubjectProgress {
  // Map where key is chapterId (e.g., "sci_c6_ch1_food_sources"), value is ChapterProgress
  final Map<String, ChapterProgress> chapters;
  final double? overallCompletion; // Optional overall % for subject

  SubjectProgress({required this.chapters, this.overallCompletion});

  factory SubjectProgress.fromMap(Map<String, dynamic> map) {
    Map<String, ChapterProgress> chapterMap = {};
    if (map['chapters'] is Map) {
      (map['chapters'] as Map).forEach((chapterId, chapterData) {
        if (chapterData is Map<String, dynamic>) {
          chapterMap[chapterId.toString()] =
              ChapterProgress.fromMap(chapterId.toString(), chapterData);
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
