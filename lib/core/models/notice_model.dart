import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeModel {
  final String id;
  final String title;
  final String message;
  final String audienceType; // e.g., "all", "specific_class"
  final String?
      classId; // Nullable, only relevant if audienceType is "specific_class"
  final String schoolId;
  final String teacherId;
  final bool isPublished;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  NoticeModel({
    required this.id,
    required this.title,
    required this.message,
    required this.audienceType,
    this.classId,
    required this.schoolId,
    required this.teacherId,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoticeModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return NoticeModel(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      message: data['message'] ?? 'No Message',
      audienceType: data['audienceType'] ?? 'all',
      classId: data['classId'], // Can be null
      schoolId: data['schoolId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      isPublished: data['isPublished'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }
}
