import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class Progress {
  String studentId;
  String subject;
  double completionPercentage;
  int topicsCovered;
  int totalTopics;
  DateTime lastUpdated;

  Progress({
    required this.studentId,
    required this.subject,
    required this.completionPercentage,
    required this.topicsCovered,
    required this.totalTopics,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        "studentId": studentId,
        "subject": subject,
        "completionPercentage": completionPercentage,
        "topicsCovered": topicsCovered,
        "totalTopics": totalTopics,
        "lastUpdated": lastUpdated,
      };

  factory Progress.fromMap(Map<String, dynamic> map) => Progress(
        studentId: map["studentId"],
        subject: map["subject"],
        completionPercentage: map["completionPercentage"],
        topicsCovered: map["topicsCovered"],
        totalTopics: map["totalTopics"],
        lastUpdated: (map["lastUpdated"] as Timestamp).toDate(),
      );
}
