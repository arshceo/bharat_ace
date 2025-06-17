import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharat_ace/core/models/notice_model.dart';
import 'package:bharat_ace/core/models/test_notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch notices: general and class-specific
  Future<List<NoticeModel>> getNotices(
      String? studentClassId, String schoolId) async {
    try {
      List<NoticeModel> notices = [];

      // Fetch notices for 'all' audiences
      QuerySnapshot<Map<String, dynamic>> generalNoticesSnapshot =
          await _firestore
              .collection('notices')
              .where('schoolId', isEqualTo: schoolId)
              .where('isPublished', isEqualTo: true)
              .where('audienceType', isEqualTo: 'all')
              .orderBy('createdAt', descending: true)
              .get();

      notices.addAll(generalNoticesSnapshot.docs
          .map((doc) => NoticeModel.fromFirestore(doc))
          .toList());

      // Fetch notices for 'specific_class' if studentClassId is available
      if (studentClassId != null && studentClassId.isNotEmpty) {
        QuerySnapshot<Map<String, dynamic>> classSpecificNoticesSnapshot =
            await _firestore
                .collection('notices')
                .where('schoolId', isEqualTo: schoolId)
                .where('isPublished', isEqualTo: true)
                .where('audienceType', isEqualTo: 'specific_class')
                .where('classId', isEqualTo: studentClassId)
                .orderBy('createdAt', descending: true)
                .get();

        notices.addAll(classSpecificNoticesSnapshot.docs
            .map((doc) => NoticeModel.fromFirestore(doc)));
      }

      // Sort all combined notices by createdAt and remove duplicates
      notices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final ids = <String>{};
      notices
          .retainWhere((notice) => ids.add(notice.id)); // Keep only unique IDs

      return notices;
    } catch (e) {
      print("Error fetching notices: $e");
      // Consider throwing a custom exception or returning an empty list with an error indicator
      return [];
    }
  }

  // Fetch tests for a specific class
  Future<List<TestNotificationModel>> getTestsForClass(
      String studentClassId, String schoolId) async {
    if (studentClassId.isEmpty) return []; // No class, no class-specific tests
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('tests')
          .where('schoolId', isEqualTo: schoolId)
          .where('classId', isEqualTo: studentClassId)
          // Consider adding a filter for testDate (e.g., only upcoming or recent)
          // .where('testDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7))))
          .orderBy('testDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TestNotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching tests: $e");
      return [];
    }
  }
}
