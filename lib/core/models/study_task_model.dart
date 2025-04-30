// lib/core/models/study_task_model.dart

class StudyTask {
  final String id; // Unique ID for the task
  final String title; // e.g., "Master Photosynthesis Basics"
  final String
      description; // e.g., "Read Chapter 3 summary, watch video, complete 5 MCQs"
  final String subject; // e.g., "Science", "Math"
  final String? chapter; // Optional: e.g., "Chapter 3: Plant Biology"
  final String? topic; // Optional: e.g., "Photosynthesis"
  final int estimatedTimeMinutes; // e.g., 45
  final int xpReward; // e.g., 100
  // Add other relevant fields like difficulty, type (read, watch, practice), links etc. later

  StudyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    this.chapter,
    this.topic,
    required this.estimatedTimeMinutes,
    required this.xpReward,
  });

  // We might not need from/toJson for this MVP if it's generated on the fly,
  // but good practice to have placeholders.
  factory StudyTask.fromJson(Map<String, dynamic> json) {
    return StudyTask(
      id: json['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString(), // Simple unique ID
      title: json['title'] ?? 'Default Task',
      description: json['description'] ?? 'Complete the assigned work.',
      subject: json['subject'] ?? 'General',
      chapter: json['chapter'],
      topic: json['topic'],
      estimatedTimeMinutes: json['estimatedTimeMinutes'] ?? 30,
      xpReward: json['xpReward'] ?? 50,
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
    };
  }
}
