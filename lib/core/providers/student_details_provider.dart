// student_details_provider.dart (Original Structure)

import 'package:bharat_ace/core/models/student_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_provider.dart'; // Assuming this exists and provides firebaseAuthProvider

// --- Database Service (Optional but Recommended) ---
class StudentDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = "students";

  Future<StudentModel?> getStudent(String uid) async {
    // ... (Implementation as before) ...
    try {
      final DocumentSnapshot<Map<String, dynamic>> studentDoc =
          await _db.collection(_collectionPath).doc(uid).get();

      if (studentDoc.exists) {
        Map<String, dynamic> data = studentDoc.data()!;
        data['id'] = studentDoc.id;
        return StudentModel.fromJson(data);
      } else {
        print("ℹ️ No student document found for UID: $uid");
        return null;
      }
    } on FirebaseException catch (e) {
      print(
          "❌ Firestore Error fetching student $uid: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("❌ Unexpected Error fetching student $uid: $e");
      rethrow;
    }
  }

  // Add other methods like updateLastActive, updateGrade if needed here
  Future<void> updateStudentLastActive(String uid) async {
    // ... implementation ...
  }
  Future<void> updateStudentGrade(String uid, String newGrade) async {
    // ... implementation ...
  }
}

final studentDatabaseServiceProvider = Provider<StudentDatabaseService>((ref) {
  return StudentDatabaseService();
});
// --- End Database Service ---

class StudentDetailsNotifier extends StateNotifier<StudentModel?> {
  // Keep Ref if using the service provider
  final Ref _ref;

  StudentDetailsNotifier(this._ref) : super(null); // Initial state is null

  /// ✅ Fetch Student Data from Firestore
  /// Returns true on success, false on failure or no user
  Future<bool> fetchStudentDetails() async {
    // Get user and DB service
    final user = _ref.read(firebaseAuthProvider).currentUser;
    final dbService = _ref.read(studentDatabaseServiceProvider);

    if (user == null) {
      if (mounted) state = null; // Clear state if no user
      print("ℹ️ fetchStudentDetails: No user logged in.");
      return false;
    }

    try {
      print("ℹ️ fetchStudentDetails: Attempting fetch for UID: ${user.uid}");
      final studentData = await dbService.getStudent(user.uid);
      if (mounted) {
        state = studentData; // Update state directly with StudentModel?
        print("✅ fetchStudentDetails: State updated.");
      }
      return true; // Indicate success
    } catch (e) {
      print("❌ Error fetching student details: $e");
      if (mounted) {
        state = null; // Set state to null on error
      }
      return false; // Indicate failure
    }
  }

  /// ✅ Set student details manually (if needed)
  void setStudentDetails(StudentModel student) {
    if (mounted) state = student;
  }

  /// ✅ Clear student details on logout
  void clearStudentDetails() {
    if (mounted) state = null;
    print("ℹ️ Student details cleared by notifier.");
  }

  // --- Optional: Methods to update specific fields if needed ---
  // These can directly use the dbService and update the state optimistically or after success
  Future<void> updateLastActive() async {
    if (state == null || state!.id.isEmpty) return;
    final dbService = _ref.read(studentDatabaseServiceProvider);
    try {
      await dbService.updateStudentLastActive(state!.id);
      if (mounted) {
        state = state!.copyWith(lastActive: Timestamp.now());
      }
    } catch (e) {
      print("❌ Error updating last active via notifier: $e");
    }
  }

  Future<void> setClass(String studentClass) async {
    if (state == null || state!.id.isEmpty) return;
    final dbService = _ref.read(studentDatabaseServiceProvider);
    final previousGrade = state!.grade; // Store for potential rollback
    // Optimistic update
    if (mounted) state = state!.copyWith(grade: studentClass);
    try {
      await dbService.updateStudentGrade(state!.id, studentClass);
    } catch (e) {
      print("❌ Error updating grade via notifier: $e");
      // Rollback optimistic update on error
      if (mounted) state = state!.copyWith(grade: previousGrade);
    }
  }
  // --- End Optional update methods ---
}

// 🔥 Riverpod Provider (Original Signature - returns StudentModel?)
final studentDetailsProvider =
    StateNotifierProvider<StudentDetailsNotifier, StudentModel?>(
  (ref) => StudentDetailsNotifier(ref), // Pass ref for service usage
);
