// lib/core/providers/notification_providers.dart
import 'package:bharat_ace/core/models/notice_model.dart';
import 'package:bharat_ace/core/models/test_notification_model.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the NotificationService instance
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider for all relevant notices (general + class-specific)
final allNoticesProvider = FutureProvider<List<NoticeModel>>((ref) async {
  final studentDetailsAsync = ref.watch(studentDetailsProvider);

  return studentDetailsAsync.when(
    data: (studentDetails) async {
      if (studentDetails == null) {
        print(
            "allNoticesProvider: Student details resolved to null. Cannot fetch notices.");
        return [];
      }

      final String studentClassId = studentDetails.grade;
      final String schoolId = studentDetails.school;

      if (schoolId.isEmpty) {
        print(
            "allNoticesProvider: School ID is empty in student details. School: '$schoolId'");
        return [];
      }

      return await ref
          .read(notificationServiceProvider)
          .getNotices(studentClassId, schoolId);
    },
    loading: () async => [],
    error: (e, st) async {
      print("allNoticesProvider: Error fetching student details: $e");
      return [];
    },
  );
});

final classTestsProvider =
    FutureProvider<List<TestNotificationModel>>((ref) async {
  final studentDetailsAsync = ref.watch(studentDetailsProvider);

  return studentDetailsAsync.when(
    data: (studentDetails) async {
      if (studentDetails == null) {
        print(
            "classTestsProvider: Student details resolved to null. Cannot fetch tests.");
        return [];
      }

      final String studentClassId = studentDetails.grade;
      final String schoolId = studentDetails.school;

      if (studentClassId.isEmpty || schoolId.isEmpty) {
        print(
            "classTestsProvider: Student class ('${studentClassId}') or School ID ('${schoolId}') is empty in student details.");
        return [];
      }

      return await ref
          .read(notificationServiceProvider)
          .getTestsForClass(studentClassId, schoolId);
    },
    loading: () async => [],
    error: (e, st) async {
      print("classTestsProvider: Error fetching student details: $e");
      return [];
    },
  );
});
