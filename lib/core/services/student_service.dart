import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Fetch student data from Firestore
  Future<void> fetchStudentData(String studentId, WidgetRef ref) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection("students").doc(studentId).get();

      if (doc.exists) {
        StudentModel student =
            StudentModel.fromJson(doc.data() as Map<String, dynamic>);
        ref.read(studentDetailsProvider.notifier).setStudentDetails(student);
        print("✅ Student details fetched and stored!");
      } else {
        print("❌ Student not found!");
      }
    } catch (e) {
      print("❌ Error fetching student: $e");
    }
  }
}
