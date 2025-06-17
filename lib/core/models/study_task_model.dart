// lib/core/models/study_task_model.dart

// ✨ NEW: Define TaskType enum
enum TaskType {
  studyTopic, // For studying a specific topic within a chapter
  studyChapter, // For studying an entire chapter
  test, // For mock tests, quizzes covering multiple topics/chapters
  revision, // For dedicated revision tasks
  assessment, // For graded assessments or assignments
  config, // For setup/initialization tasks (e.g., "Set exam date")
  reading, // General reading task
  video, // Task involves watching a video
  quiz, // Short quiz, possibly topic-specific
  experiment, // Hands-on experiment or practical work
  project, // Longer-term project work
  other, // Fallback for types not explicitly listed
  unknown, // For cases where type string from JSON doesn't match
}

// Helper function to convert string from JSON to TaskType
TaskType _taskTypeFromString(String? typeString) {
  if (typeString == null) return TaskType.unknown;
  switch (typeString.toLowerCase().replaceAll('_', '').replaceAll('-', '')) {
    // Normalize common separators
    case 'studytopic':
      return TaskType.studyTopic;
    case 'studychapter':
      return TaskType.studyChapter;
    case 'test':
      return TaskType.test;
    case 'revision':
      return TaskType.revision;
    case 'assessment':
      return TaskType.assessment;
    case 'config':
    case 'configuration':
    case 'setup':
      return TaskType.config;
    case 'reading':
      return TaskType.reading;
    case 'video':
    case 'watchvideo':
      return TaskType.video;
    case 'quiz':
      return TaskType.quiz;
    case 'experiment':
      return TaskType.experiment;
    case 'project':
      return TaskType.project;
    case 'other':
      return TaskType.other;
    default:
      // Attempt to match enum member names directly (case-insensitive)
      for (TaskType enumValue in TaskType.values) {
        if (enumValue.name.toLowerCase() == typeString.toLowerCase()) {
          return enumValue;
        }
      }
      print(
          "Warning: Unknown TaskType string '$typeString', defaulting to TaskType.unknown");
      return TaskType.unknown;
  }
}

// Helper function to convert TaskType enum to a string for JSON
String _taskTypeToString(TaskType type) {
  // Returns the enum member name, e.g., "studyTopic"
  return type.name;
}

class StudyTask {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String? chapter;
  final String? topic;
  final int estimatedTimeMinutes;
  final int xpReward;
  final double? progress;
  final TaskType type;
  final String? level; // ✨ CHANGED: from String? to TaskType
  final bool isCompleted;

  StudyTask({
    required this.id,
    required this.title,
    this.description = "", // Providing a default if not always passed
    required this.subject,
    this.chapter,
    this.topic,
    required this.estimatedTimeMinutes,
    required this.xpReward,
    this.progress,
    required this.type,
    this.level,
    // ✨ CHANGED: Now requires TaskType
    this.isCompleted = false,
  });

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    double? parsedProgress;
    if (json['progress'] != null) {
      if (json['progress'] is int) {
        parsedProgress = (json['progress'] as int).toDouble() / 100.0;
      } else if (json['progress'] is double) {
        parsedProgress = json['progress'] as double;
      }
      parsedProgress = parsedProgress?.clamp(0.0, 1.0);
    }

    bool taskIsCompleted = json['isCompleted'] as bool? ??
        (parsedProgress != null && parsedProgress >= 1.0);

    return StudyTask(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Default Task',
      description:
          json['description'] as String? ?? 'Complete the assigned work.',
      subject: json['subject'] as String? ?? 'General',
      chapter: json['chapter'] as String?,
      topic: json['topic'] as String?,
      estimatedTimeMinutes: json['estimatedTimeMinutes'] as int? ?? 30,
      xpReward: json['xpReward'] as int? ?? 50,
      progress: parsedProgress,
      type: _taskTypeFromString(json['type'] as String?),
      level: json['level'] as String?,
      isCompleted: taskIsCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'chapter': chapter,
      'topic': topic,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'xpReward': xpReward,
      'progress': progress,
      'level': level, // ✨ Include level in JSON
      'type':
          _taskTypeToString(type), // ED: Use helper to convert enum to string
      'isCompleted': isCompleted,
    };
  }

  StudyTask copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? chapter,
    String? topic,
    int? estimatedTimeMinutes,
    int? xpReward,
    String? level,
    double? progress,
    TaskType? type, // ✨ CHANGED: Parameter type is TaskType
    bool? isCompleted,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      topic: topic ?? this.topic,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      xpReward: xpReward ?? this.xpReward,
      progress: progress ?? this.progress,
      type: type ?? this.type,
      level: level ?? this.level, // ✨
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return 'StudyTask(id: $id, title: "$title", subject: $subject, progress: ${progress?.toStringAsFixed(2)}, completed: $isCompleted, lvl: $level,  type: ${type.name})'; // ✨ Use type.name for string representation
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StudyTask &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.subject == subject &&
        other.chapter == chapter &&
        other.topic == topic &&
        other.estimatedTimeMinutes == estimatedTimeMinutes &&
        other.xpReward == xpReward &&
        other.progress == progress &&
        other.type == type &&
        other.level == level && // ✨ Compare level directly
        // ✨ Compare enum directly
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        subject.hashCode ^
        chapter.hashCode ^
        topic.hashCode ^
        estimatedTimeMinutes.hashCode ^
        xpReward.hashCode ^
        progress.hashCode ^
        level.hashCode ^ // ✨ Hash level directly
        type.hashCode ^ // ✨ Hash enum directly
        isCompleted.hashCode;
  }
}
