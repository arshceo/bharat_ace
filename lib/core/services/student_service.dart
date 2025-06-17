// lib/core/services/your_student_service_file.dart (assuming this is where StudentService is)
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart'; // This file now exports studentDetailsNotifierProvider
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for your StudentService (if you want to inject it via Riverpod)
final studentServiceDepProvider = Provider((ref) => StudentService(ref));

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref; // Store Ref if the service is created via a Riverpod provider

  // Constructor to receive Ref if creating StudentService via Riverpod
  StudentService(this._ref);

  // OR if you are calling this method from a place that already has `ref` (like a widget or another provider)
  // you can pass `ref` as a parameter, but it's cleaner for a service to hold its own `ref` if created by Riverpod.

  // ✅ Fetch student data from Firestore
  // If StudentService is NOT provided by Riverpod, then you must pass Ref to its methods
  Future<void> fetchStudentData(
      String studentId /*, Ref externalRef (if not holding _ref) */) async {
    // Use _ref if the service holds it, otherwise use passed externalRef
    final refToUse = _ref; // or externalRef if you pass it

    if (studentId.isEmpty) {
      print("❌ studentId is empty in fetchStudentData");
      return;
    }

    try {
      print("StudentService: Fetching data for student ID: $studentId");
      DocumentSnapshot<Map<String, dynamic>>
          doc = // Specify types for DocumentSnapshot
          await _firestore.collection("students").doc(studentId).get();

      if (doc.exists && doc.data() != null) {
        StudentModel student = StudentModel.fromJson(doc
            .data()!); // Use ! because we checked doc.exists and data() != null
        // CORRECT WAY to access the notifier:
        refToUse
            .read(studentDetailsNotifierProvider.notifier)
            .setStudentDetails(student);
        print(
            "✅ Student details fetched and stored via StudentService for ${student.name}!");
      } else {
        print("❌ Student not found in Firestore with ID: $studentId");
        // Optionally, clear the student details if a fetch for a specific ID returns nothing
        // refToUse.read(studentDetailsNotifierProvider.notifier).clearStudentDetails(); // If appropriate
      }
    } catch (e) {
      print("❌ Error fetching student in StudentService: $e");
      // Potentially clear details on error too, or let the notifier handle its own error state
      // refToUse.read(studentDetailsNotifierProvider.notifier).clearStudentDetails();
    }
  }
}
