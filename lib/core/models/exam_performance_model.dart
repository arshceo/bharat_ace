import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class ExamPerformance {
  String studentId;
  String subject;
  String examType; // Class Test, Mid-Term, Final Exam
  double score;
  double totalMarks;
  String teacherFeedback;
  DateTime examDate;

  ExamPerformance({
    required this.studentId,
    required this.subject,
    required this.examType,
    required this.score,
    required this.totalMarks,
    required this.teacherFeedback,
    required this.examDate,
  });

  Map<String, dynamic> toMap() => {
        "studentId": studentId,
        "subject": subject,
        "examType": examType,
        "score": score,
        "totalMarks": totalMarks,
        "teacherFeedback": teacherFeedback,
        "examDate": examDate,
      };

  factory ExamPerformance.fromMap(Map<String, dynamic> map) => ExamPerformance(
        studentId: map["studentId"],
        subject: map["subject"],
        examType: map["examType"],
        score: map["score"],
        totalMarks: map["totalMarks"],
        teacherFeedback: map["teacherFeedback"],
        examDate: (map["examDate"] as Timestamp).toDate(),
      );
}
