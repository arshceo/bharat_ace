// lib/core/models/syllabus_models.dart (New or Updated File)

// Represents a prerequisite concept
// Represents a suggested activity within a topic
class SuggestedActivity {
  final String type; // e.g., "list", "explain", "match"
  final String description;

  SuggestedActivity({required this.type, required this.description});

  factory SuggestedActivity.fromJson(Map<String, dynamic> json) {
    return SuggestedActivity(
      type: json['type'] ?? 'discuss',
      description: json['description'] ?? '',
    );
  }
}

// Represents a topic within a level
class Topic {
  final String topicId;
  final String topicTitle;
  final int importance; // 1-5
  final int difficulty; // 1-5
  final List<String> concepts;
  final List<String> keywords;
  final List<String> aiPromptHints;
  final List<SuggestedActivity>
      suggestedActivities; // Changed to list of objects
  final int? estimatedStudyTimeMinutes;
  Topic({
    required this.topicId,
    required this.topicTitle,
    required this.importance,
    required this.difficulty,
    required this.concepts,
    required this.keywords,
    required this.aiPromptHints,
    required this.suggestedActivities,
    this.estimatedStudyTimeMinutes,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      topicId: json['topicId'] ?? '',
      topicTitle: json['topicTitle'] ?? 'Unnamed Topic',
      importance: json['importance'] ?? 3,
      difficulty: json['difficulty'] ?? 3,
      concepts: List<String>.from(json['concepts'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      aiPromptHints: List<String>.from(json['aiPromptHints'] ?? []),
      // Parse suggested activities
      suggestedActivities: (json['suggestedActivities'] as List<dynamic>?)
              ?.map((activityJson) => SuggestedActivity.fromJson(
                  activityJson as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedStudyTimeMinutes:
          json['estimatedStudyTimeMinutes'] as int?, // ✨ PARSE THIS
    );
  }
}

// Represents assessment criteria for a level
class AssessmentCriteria {
  final double passScore; // e.g., 0.70
  final List<String> requiredSkills;
  final String assessmentType; // e.g., "mcq_short_answer"

  AssessmentCriteria(
      {required this.passScore,
      required this.requiredSkills,
      required this.assessmentType});

  factory AssessmentCriteria.fromJson(Map<String, dynamic> json) {
    return AssessmentCriteria(
      passScore: (json['passScore'] as num?)?.toDouble() ??
          0.7, // Handle num conversion
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      assessmentType: json['assessmentType'] ?? 'mcq',
    );
  }
}

// Represents a proficiency level within a chapter
class Level {
  final String levelName; // "Fundamentals", "Intermediate", "Advanced"
  final List<String> learningObjectives;
  final List<Topic> topics;
  final AssessmentCriteria assessmentCriteria;

  Level({
    required this.levelName,
    required this.learningObjectives,
    required this.topics,
    required this.assessmentCriteria,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      levelName: json['levelName'] ?? 'Unknown Level',
      learningObjectives: List<String>.from(json['learningObjectives'] ?? []),
      topics: (json['topics'] as List<dynamic>?)
              ?.map((topicJson) =>
                  Topic.fromJson(topicJson as Map<String, dynamic>))
              .toList() ??
          [],
      assessmentCriteria:
          AssessmentCriteria.fromJson(json['assessmentCriteria'] ?? {}),
    );
  }
}

// Represents a chapter with levels and prerequisites
// --- Inside lib/core/models/syllabus_models.dart ---

// Assuming Prerequisite and Level models are defined above or imported correctly

class ChapterDetailed {
  final String chapterId;
  final String chapterTitle;
  final String description;
  final List<String> prerequisites; // NEW: List of strings
  final List<Level> levels;
  final List<String> coreTopics; // <<< --- ADD THIS LINE ---
  final int? estimatedStudyTimeMinutes;
  ChapterDetailed({
    required this.chapterId,
    required this.chapterTitle,
    required this.description,
    required this.prerequisites,
    required this.levels,
    required this.coreTopics, // <<< --- ADD THIS LINE ---
    this.estimatedStudyTimeMinutes,
  });

  // From your lib/core/models/syllabus_models.dart
  factory ChapterDetailed.fromJson(Map<String, dynamic> json) {
    List<String> parsedPrerequisites = [];
    if (json['prerequisites'] is List) {
      print(
          "[DEBUG ChapterDetailed.fromJson]   'prerequisites' is a List. Iterating...");
      for (var i = 0; i < (json['prerequisites'] as List).length; i++) {
        var item = (json['prerequisites'] as List)[i];
        print(
            "[DEBUG ChapterDetailed.fromJson]     Item $i (type: ${item?.runtimeType}): $item");
        if (item is String) {
          parsedPrerequisites.add(item);
          print(
              "[DEBUG ChapterDetailed.fromJson]       Added item $i as String.");
        } else {
          print(
              "[DEBUG ChapterDetailed.fromJson]       SKIPPED item $i because it's NOT a String.");
        }
      }
    } else if (json['prerequisites'] == null) {
      print(
          "[DEBUG ChapterDetailed.fromJson]   'prerequisites' key is NULL or MISSING.");
    } else {
      print(
          "[DEBUG ChapterDetailed.fromJson]   'prerequisites' is NOT a List (type: ${json['prerequisites']?.runtimeType}). Value: ${json['prerequisites']}");
    }
    print(
        "[DEBUG ChapterDetailed.fromJson]   FINAL parsedPrerequisites for ${json['chapterId']} (length: ${parsedPrerequisites.length}): $parsedPrerequisites");

    return ChapterDetailed(
      chapterId: json['chapterId'] as String? ?? '',
      chapterTitle: json['chapterTitle'] as String? ?? 'Unnamed Chapter',
      description: json['description'] as String? ?? '',
      prerequisites: parsedPrerequisites, // Use the debugged list
      levels: (json['levels'] as List<dynamic>?)
              ?.map((levelJson) {
                if (levelJson is Map<String, dynamic>) {
                  return Level.fromJson(levelJson);
                }
                print(
                    "Warning: Invalid item in 'levels' list: $levelJson. Skipping.");
                return null;
              })
              .where((level) => level != null)
              .cast<Level>()
              .toList() ??
          [],
      coreTopics: List<String>.from(json['coreTopics'] as List<dynamic>? ?? []),
      estimatedStudyTimeMinutes:
          json['estimatedStudyTimeMinutes'] as int?, // ✨ PARSE THIS
    );
  }

  // *** ADD THIS FACTORY CONSTRUCTOR ***
  /// Creates an empty/default ChapterDetailed object.
  factory ChapterDetailed.empty() {
    print("Warning: Using empty ChapterDetailed placeholder."); // Optional log
    return ChapterDetailed(
      chapterId: '', // Empty ID signifies it's a placeholder/not found
      chapterTitle: 'Not Found',
      description: '',
      prerequisites: [], // Empty list
      levels: [], // Empty list
      coreTopics: [], // <<< --- ADD THIS LINE ---
      estimatedStudyTimeMinutes: null, // No estimated time
    );
  }
  // *** END OF ADDED FACTORY ***
} // End of ChapterDetailed class

// Represents a subject containing detailed chapters
class SubjectDetailed {
  final String subjectId;
  final List<ChapterDetailed> chapters;
  // Add subSubjects map if needed for complex subjects like SST
  final Map<String, SubjectDetailed>? subSubjects;

  SubjectDetailed(
      {required this.subjectId, required this.chapters, this.subSubjects});

  factory SubjectDetailed.fromJson(String id, Map<String, dynamic> json) {
    Map<String, SubjectDetailed>? parsedSubSubjects;
    if (json.containsKey('subSubjects') && json['subSubjects'] is Map) {
      parsedSubSubjects = (json['subSubjects'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
              key,
              SubjectDetailed.fromJson(
                  value['subjectId'] ?? key, value as Map<String, dynamic>)));
    }

    return SubjectDetailed(
      subjectId: id,
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((chapJson) =>
                  ChapterDetailed.fromJson(chapJson as Map<String, dynamic>))
              .toList() ??
          [],
      subSubjects: parsedSubSubjects,
    );
  }
}

// Represents the entire syllabus for a class
class Syllabus {
  final String className;
  final String board;
  final Map<String, SubjectDetailed>
      subjects; // Subject Name -> SubjectDetailed

  Syllabus(
      {required this.className, required this.board, required this.subjects});

  factory Syllabus.fromJson(Map<String, dynamic> json) {
    // This factory would typically be used by the provider after loading the raw map
    final rawSubjects = json['subjects'] as Map<String, dynamic>? ?? {};
    return Syllabus(
      className: json['class'] ?? '',
      board: json['board'] ?? '',
      subjects: rawSubjects.map((key, value) => MapEntry(
          key,
          SubjectDetailed.fromJson(
              value['subjectId'] ?? key, value as Map<String, dynamic>))),
    );
  }
}
