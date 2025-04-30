// student_details_provider.dart (Modified as per Step 1)

import 'package:bharat_ace/core/models/student_model.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'auth_provider.dart'; // Assuming this exists and provides firebaseAuthProvider

// --- Database Service ---
class StudentDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = "students";

  Future<StudentModel?> getStudent(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> studentDoc =
          await _db.collection(_collectionPath).doc(uid).get();
      if (studentDoc.exists) {
        Map<String, dynamic> data = studentDoc.data()!;
        data['id'] = studentDoc.id;
        return StudentModel.fromJson(data);
      } else {
        print("ℹ️ DB Service: No student document found for UID: $uid");
        return null;
      }
    } catch (e) {
      print("❌ DB Service Error fetching student $uid: $e");
      rethrow;
    }
  }

  Future<void> updateStudentLastActive(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _db
          .collection(_collectionPath)
          .doc(uid)
          .update({"lastActive": Timestamp.now()});
    } catch (e) {
      print("DB Service Error updateLastActive: $e");
      rethrow;
    }
  }

  Future<void> updateStudentGrade(String uid, String newGrade) async {
    if (uid.isEmpty) return;
    try {
      await _db
          .collection(_collectionPath)
          .doc(uid)
          .update({"grade": newGrade});
    } catch (e) {
      print("DB Service Error updateStudentGrade: $e");
      rethrow;
    }
  }

  /// Sets (creates or overwrites) the entire student document in Firestore.
  Future<void> setStudentData(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) {
      throw ArgumentError("Student UID cannot be empty when saving data.");
    }
    try {
      await _db.collection(_collectionPath).doc(uid).set(data);
      print("✅ DB Service: Student data set successfully for $uid");
    } catch (e) {
      print("❌ DB Service Error setting student data for $uid: $e");
      rethrow;
    }
  }
}

final studentDatabaseServiceProvider = Provider<StudentDatabaseService>((ref) {
  return StudentDatabaseService();
});
// --- End Database Service ---

// --- State Notifier ---
class StudentDetailsNotifier extends StateNotifier<StudentModel?> {
  final Ref _ref;

  StudentDetailsNotifier(this._ref) : super(null);

  /// Ensures state exists, creating a minimal one if needed.
  StudentModel _ensureStateExists(String uid, String email) {
    if (state == null) {
      print(
          "Notifier: State is null, initializing minimal student state for $uid");
      return StudentModel(
          id: uid,
          email: email,
          username: "",
          name: "",
          phone: "",
          school: "",
          board: "",
          grade: "",
          enrolledSubjects: [],
          createdAt: Timestamp.now(),
          lastActive: Timestamp.now(),
          xp: 0,
          isPremium: false,
          avatar: "",
          deviceInfo: {});
    }
    return state!;
  }

  /// Fetches student data. Called by initializer/listener.
  Future<bool> fetchStudentDetails() async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      if (mounted) state = null;
      return false;
    }
    final dbService = _ref.read(studentDatabaseServiceProvider);
    try {
      final studentData = await dbService.getStudent(user.uid);
      if (mounted) state = studentData;
      return true;
    } catch (e) {
      print("❌ Notifier Error fetching student details: $e");
      if (mounted) state = null;
      return false;
    }
  }

  /// Manually sets state (e.g., for testing or specific overrides).
  void setStudentDetails(StudentModel student) {
    if (mounted) state = student;
  }

  /// Clears state on logout.
  void clearStudentDetails() {
    if (mounted) state = null;
  }

  /// Updates grade in state (Onboarding Step). NO DB SAVE.
  void setClass(String studentClass) async {
    // Keep async if needed later, but DB part removed
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    final currentState = _ensureStateExists(user.uid, user.email ?? "");
    if (mounted) state = currentState.copyWith(grade: studentClass);
    print("Notifier: Updated grade in state to $studentClass");
    // Removed DB call - assuming save happens at end of onboarding
  }

  /// Updates profile details in state (Onboarding Step). NO DB SAVE.
  void updateProfileDetails(
      {required String name,
      required String username,
      required String phone,
      required String? board,
      required String? school,
      required String avatar}) {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    final currentState = _ensureStateExists(user.uid, user.email ?? "");
    if (mounted) {
      state = currentState.copyWith(
          name: name,
          username: username,
          phone: phone,
          board: board,
          school: school,
          avatar: avatar);
      print("Notifier: Updated profile details in state.");
    }
  }

  /// Updates enrolled subjects in state (Onboarding Step). NO DB SAVE.
  void updateEnrolledSubjects(List<String> subjects) {
    if (state == null) {
      print("❌ Error: Cannot update subjects, state is null.");
      return;
    }
    if (mounted) {
      state = state!.copyWith(enrolledSubjects: subjects);
      print("Notifier: Updated subjects in state.");
    }
  }

  /// Saves the final, complete student data from state to Firestore.
  Future<void> saveStudentDataToFirestore() async {
    if (state == null) throw Exception("Student data is incomplete.");
    if (state!.id.isEmpty) throw Exception("Student ID is missing.");
    // Add more validation if needed
    if (state!.grade.isEmpty || state!.board.isEmpty) {
      throw Exception("Essential profile data (Grade/Board) is missing.");
    }

    final dbService = _ref.read(studentDatabaseServiceProvider);
    try {
      print(
          "Notifier: Saving final student data to Firestore for ${state!.id}");
      Map<String, dynamic> studentData = state!.toJson();
      await dbService.setStudentData(
          state!.id, studentData); // Call service to save
      print("✅ Notifier: Student data saved successfully.");
    } catch (e) {
      print("❌ Notifier: Error saving student data: $e");
      rethrow;
    }
  }

  /// Optional: Updates last active timestamp (can be called from anywhere).
  Future<void> updateLastActive() async {
    if (state == null || state!.id.isEmpty) return;
    final dbService = _ref.read(studentDatabaseServiceProvider);
    try {
      await dbService.updateStudentLastActive(state!.id);
      if (mounted) state = state!.copyWith(lastActive: Timestamp.now());
    } catch (e) {
      print("❌ Error updating last active via notifier: $e");
    }
  }
}

final studentDetailsFetcher = Provider<void>((ref) {
  print("ℹ️ Initializing studentDetailsFetcher listener.");
  ref.listen<AsyncValue<User?>>(authStateProvider,
      (previousAuthState, currentAuthState) {
    print("👂 Auth state listener triggered.");
    final notifier = ref.read(studentDetailsProvider.notifier);
    final User? currentUser = currentAuthState.valueOrNull;

    if (currentUser != null) {
      print("👂 Auth Listener: User logged in (UID: ${currentUser.uid}).");
      final StudentModel? currentStudentData =
          ref.read(studentDetailsProvider); // Read current state value
      // Fetch only if state is null or for a different user.
      if (currentStudentData == null ||
          currentStudentData.id != currentUser.uid) {
        print("👂 Auth Listener: Triggering fetchStudentDetails.");
        notifier.fetchStudentDetails(); // Call fetch on the notifier
      } else {
        print(
            "👂 Auth Listener: Student details already loaded for ${currentUser.uid}.");
        // Optional: You could trigger an updateLastActive here if desired
        // notifier.updateLastActive();
      }
    } else {
      print("👂 Auth Listener: User logged out.");
      notifier.clearStudentDetails(); // Clear student data
    }
  });
}, name: 'studentDetailsFetcher');
// --- End State Notifier ---

// --- Riverpod Provider ---
final studentDetailsProvider =
    StateNotifierProvider<StudentDetailsNotifier, StudentModel?>(
  (ref) => StudentDetailsNotifier(ref),
);
// --- End Riverpod Provider ---
