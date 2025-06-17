import 'package:cloud_firestore/cloud_firestore.dart';

class TestNotificationModel {
  final String id;
  final String title;
  final String classId;
  final String subjectId;
  final String teacherId;
  final String schoolId;
  final Timestamp testDate;
  final int maxMarks;
  final String type; // e.g., "class_test"
  final Timestamp createdAt;
  final Timestamp updatedAt;

  TestNotificationModel({
    required this.id,
    required this.title,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.schoolId,
    required this.testDate,
    required this.maxMarks,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TestNotificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return TestNotificationModel(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      classId: data['classId'] ?? '',
      subjectId: data['subjectId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      schoolId: data['schoolId'] ?? '',
      testDate: data['testDate'] ?? Timestamp.now(),
      maxMarks: data['maxMarks'] ?? 0,
      type: data['type'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }
}
