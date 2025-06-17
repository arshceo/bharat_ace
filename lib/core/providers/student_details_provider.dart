// lib/core/providers/student_details_provider.dart

import 'package:bharat_ace/core/models/student_model.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart'; // Assuming this provides firebaseAuthProvider or authStateProvider

// --- Database Service ---
class StudentDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = "students";

  Future<void> updateStudentXpAndStreak(String uid, int newTotalXp,
      int newStreak, Timestamp? newLastXpDate) async {
    if (uid.isEmpty) {
      print("DB Service Error: UID empty, cannot update XP and streak.");
      return;
    }
    try {
      Map<String, dynamic> updateData = {
        "xp": newTotalXp,
        "dailyStreak": newStreak,
      };
      if (newLastXpDate != null) {
        updateData["lastXpEarnedDate"] = newLastXpDate;
      } else {
        // If newLastXpDate is null (e.g., streak reset, no active last earn date)
        updateData["lastXpEarnedDate"] = FieldValue.delete();
      }

      await _db.collection(_collectionPath).doc(uid).update(updateData);
      print(
          "✅ DB Service: XP updated to $newTotalXp, Streak to $newStreak for $uid. LastXPDate action: ${newLastXpDate == null ? 'deleted' : 'set'}.");
    } catch (e) {
      print("❌ DB Service Error updating student XP and streak for $uid: $e");
      rethrow;
    }
  }

  // This method is still useful if you only want to update XP without affecting streak logic directly
  // (though our current addXp handles streak, so this might be less used now)
  Future<void> updateStudentXp(String uid, int newTotalXp) async {
    if (uid.isEmpty) {
      print("DB Service Error: UID empty, cannot update XP.");
      return;
    }
    try {
      await _db.collection(_collectionPath).doc(uid).update({"xp": newTotalXp});
      print("✅ DB Service: XP updated to $newTotalXp for $uid.");
    } catch (e) {
      print("❌ DB Service Error updating student XP for $uid: $e");
      rethrow;
    }
  }

  // Method to update only streak and potentially lastXpEarnedDate (used by _checkAndResetStreakIfNeeded)
  Future<void> updateStudentStreakOnly(String uid, int newStreak,
      {bool clearLastXpDate = false}) async {
    if (uid.isEmpty) {
      print("DB Service Error: UID empty, cannot update streak.");
      return;
    }
    try {
      Map<String, dynamic> updateData = {
        "dailyStreak": newStreak,
      };
      if (clearLastXpDate) {
        updateData["lastXpEarnedDate"] = FieldValue.delete();
      }
      await _db.collection(_collectionPath).doc(uid).update(updateData);
      print(
          "✅ DB Service: Streak updated to $newStreak for $uid. ClearLastXpDate: $clearLastXpDate");
    } catch (e) {
      print("❌ DB Service Error updating student streak for $uid: $e");
      rethrow;
    }
  }

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

  Future<void> setStudentData(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) {
      throw ArgumentError("Student UID cannot be empty when saving data.");
    }
    try {
      // Using .set with merge: true will create if not exists, and update if exists.
      // If you want to strictly update only specific fields and fail if doc doesn't exist,
      // use .update(). For general profile saving, .set(..., SetOptions(merge: true)) is often safer.
      await _db
          .collection(_collectionPath)
          .doc(uid)
          .set(data, SetOptions(merge: true));
      print("✅ DB Service: Student data set/merged successfully for $uid");
    } catch (e) {
      print("❌ DB Service Error setting/merging student data for $uid: $e");
      rethrow;
    }
  }

  /// Updates specific fields of a student document.
  Future<void> updateStudentSpecificFields(
      String uid, Map<String, dynamic> updates) async {
    if (uid.isEmpty) {
      throw ArgumentError("Student UID cannot be empty when updating fields.");
    }
    try {
      await _db.collection(_collectionPath).doc(uid).update(updates);
      print("✅ DB Service: Specific fields updated for $uid: $updates");
    } catch (e) {
      print("❌ DB Service Error updating specific fields for $uid: $e");
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
  bool _isFetching = false;
  Object? _fetchError;
  StackTrace? _fetchStackTrace;

  StudentDetailsNotifier(this._ref) : super(null) {
    _initialize();
  }

  void _initialize() {
    _ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      print(
          "StudentDetailsNotifier: Auth state changed. New user: ${next.valueOrNull?.uid}");
      final user = next.valueOrNull;
      if (user != null) {
        if (state == null || state!.id != user.uid) {
          fetchStudentDetails().then((_) {
            if (mounted && state != null) {
              _checkAndResetStreakIfNeeded();
            }
          });
        } else {
          _checkAndResetStreakIfNeeded();
        }
      } else {
        clearStudentDetails();
      }
    }, fireImmediately: true);
  }

  Future<void> updateStudentExamDates(
      {DateTime? finalExamDate, DateTime? mstDate}) async {
    if (state == null) {
      print(
          "StudentDetailsNotifier: Cannot update exam dates. Student data not loaded.");
      return;
    }
    final StudentModel currentStudent = state!;
    final dbService = _ref.read(studentDatabaseServiceProvider);
    Map<String, dynamic> updates = {};
    bool needsDbUpdate = false;

    if (finalExamDate != null && finalExamDate != currentStudent.examDate) {
      updates['examDate'] = Timestamp.fromDate(finalExamDate);
      needsDbUpdate = true;
    } else if (finalExamDate == null && currentStudent.examDate != null) {
      updates['examDate'] = FieldValue.delete();
      needsDbUpdate = true;
    }

    if (mstDate != null && mstDate != currentStudent.mstDate) {
      updates['mstDate'] = Timestamp.fromDate(mstDate);
      needsDbUpdate = true;
    } else if (mstDate == null && currentStudent.mstDate != null) {
      updates['mstDate'] = FieldValue.delete();
      needsDbUpdate = true;
    }

    if (needsDbUpdate && updates.isNotEmpty) {
      try {
        await dbService.updateStudentSpecificFields(currentStudent.id, updates);
        if (mounted && state != null && state!.id == currentStudent.id) {
          state = currentStudent.copyWith(
            examDateOption: () => finalExamDate,
            mstDateOption: () => mstDate,
          );
          print(
              "StudentDetailsNotifier: Exam dates updated locally and in Firestore.");
        }
      } catch (e, s) {
        print(
            "❌ StudentDetailsNotifier: Error updating student exam dates in Firestore: $e");
        if (mounted && state != null && state?.id == currentStudent.id) {
          // Keep existing data but signal error, or just log
          // state = AsyncValue.error(e,s, previousData: state.value); // Example if you want to show error but keep old data
        }
      }
    } else {
      print(
          "StudentDetailsNotifier: No changes in exam dates or no dates provided for update.");
    }
  }

  Future<void> fetchStudentDetails() async {
    if (_isFetching) {
      print("StudentDetailsNotifier: Fetch already in progress. Skipping.");
      return;
    }

    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      if (mounted) {
        state = null;
        _fetchError = null;
        _fetchStackTrace = null;
      }
      print("StudentDetailsNotifier: No user logged in. Cannot fetch.");
      return;
    }

    _isFetching = true;
    _fetchError = null;
    _fetchStackTrace = null;
    print("StudentDetailsNotifier: Fetching details for ${user.uid}...");
    final dbService = _ref.read(studentDatabaseServiceProvider);
    try {
      final studentData = await dbService.getStudent(user.uid);
      if (mounted) {
        state = studentData;
        print(studentData != null
            ? "StudentDetailsNotifier: Details fetched: ${studentData.name}"
            : "StudentDetailsNotifier: No student record found in DB for ${user.uid}.");
      }
    } catch (e, s) {
      print("❌ Notifier Error fetching student details: $e");
      if (mounted) {
        state = null;
        _fetchError = e;
        _fetchStackTrace = s;
      }
    } finally {
      if (mounted) {
        _isFetching = false;
      }
    }
  }

  void clearStudentDetails() {
    if (mounted) {
      state = null;
      _isFetching = false;
      _fetchError = null;
      _fetchStackTrace = null;
      print("StudentDetailsNotifier: Cleared student details.");
    }
  }

  Future<void> _checkAndResetStreakIfNeeded() async {
    if (state == null || state!.id.isEmpty) {
      return;
    }

    final StudentModel currentStudent = state!;
    bool streakNeedsUpdateInDb = false;
    int newStreakValue = currentStudent.dailyStreak;
    bool clearLastXpDateForDb = false; // Flag to pass to DB service

    if (currentStudent.lastXpEarnedDate != null) {
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime lastXpDateTime = currentStudent.lastXpEarnedDate!.toDate();
      final DateTime lastXpDateNormalized = DateTime(
          lastXpDateTime.year, lastXpDateTime.month, lastXpDateTime.day);

      if (lastXpDateNormalized
          .isBefore(today.subtract(const Duration(days: 1)))) {
        if (currentStudent.dailyStreak > 0) {
          newStreakValue = 0;
          clearLastXpDateForDb =
              true; // Since streak is reset, clear the last earned date
          streakNeedsUpdateInDb = true;
          print(
              "StudentDetailsNotifier: Streak reset to 0 for ${currentStudent.id} due to inactivity. LastXPDate will be cleared.");
        }
      }
    } else if (currentStudent.dailyStreak > 0) {
      newStreakValue = 0;
      clearLastXpDateForDb =
          true; // No lastXpDate but had a streak, inconsistent, clear.
      streakNeedsUpdateInDb = true;
      print(
          "StudentDetailsNotifier: Streak reset to 0 for ${currentStudent.id} due to missing lastXpEarnedDate. LastXPDate will be cleared.");
    }

    if (streakNeedsUpdateInDb) {
      final originalStateBeforeDbCall = state; // For potential revert

      // Optimistically update local state
      if (mounted) {
        state = currentStudent.copyWith(
          dailyStreak: newStreakValue,
          // If clearing in DB, also update local state to reflect that
          lastXpEarnedDateOption: () =>
              clearLastXpDateForDb ? null : currentStudent.lastXpEarnedDate,
        );
      }

      final dbService = _ref.read(studentDatabaseServiceProvider);
      try {
        await dbService.updateStudentStreakOnly(
            currentStudent.id, newStreakValue,
            clearLastXpDate: clearLastXpDateForDb);
        print(
            "StudentDetailsNotifier: Streak updated in Firestore after check to $newStreakValue.");
      } catch (e) {
        print(
            "❌ StudentDetailsNotifier: Error updating streak in Firestore after check: $e");
        if (mounted && originalStateBeforeDbCall != null) {
          state = originalStateBeforeDbCall; // Revert
        }
      }
    }
  }

  Future<void> addXp(int amountToAdd) async {
    if (state == null || state!.id.isEmpty) {
      print(
          "StudentDetailsNotifier: Cannot add XP. Student state is null or ID is empty.");
      return;
    }
    if (amountToAdd <= 0) {
      print(
          "StudentDetailsNotifier: XP Amount to add must be positive. Amount: $amountToAdd");
      return;
    }

    final originalStudentState = state!;
    final newTotalXp = originalStudentState.xp + amountToAdd;

    int updatedStreak = originalStudentState.dailyStreak;
    Timestamp? updatedLastXpEarnedDate = originalStudentState.lastXpEarnedDate;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    DateTime? lastXpDateNormalized;
    if (originalStudentState.lastXpEarnedDate != null) {
      final lastXpDateTime = originalStudentState.lastXpEarnedDate!.toDate();
      lastXpDateNormalized = DateTime(
          lastXpDateTime.year, lastXpDateTime.month, lastXpDateTime.day);
    }

    if (lastXpDateNormalized == null || lastXpDateNormalized.isBefore(today)) {
      if (lastXpDateNormalized != null &&
          lastXpDateNormalized
              .isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
        updatedStreak++;
      } else {
        updatedStreak = 1;
      }
      updatedLastXpEarnedDate = Timestamp.fromDate(today);
      print(
          "StudentDetailsNotifier: Streak updated to $updatedStreak. Last XP date set to: $updatedLastXpEarnedDate");
    } else {
      print(
          "StudentDetailsNotifier: XP already earned today. Streak ($updatedStreak) and last XP date ($updatedLastXpEarnedDate) not changed by this event.");
    }

    if (mounted) {
      state = originalStudentState.copyWith(
        xp: newTotalXp,
        dailyStreak: updatedStreak,
        lastXpEarnedDateOption: () =>
            updatedLastXpEarnedDate, // CORRECTED: Use closure
      );
      print(
          "StudentDetailsNotifier: Local state updated - XP: $newTotalXp, Streak: $updatedStreak for ${originalStudentState.id}.");
    }

    final dbService = _ref.read(studentDatabaseServiceProvider);
    try {
      await dbService.updateStudentXpAndStreak(originalStudentState.id,
          newTotalXp, updatedStreak, updatedLastXpEarnedDate);
      print(
          "StudentDetailsNotifier: XP and Streak successfully updated in Firestore for ${originalStudentState.id}.");
    } catch (e) {
      print(
          "❌ StudentDetailsNotifier: Error saving XP and Streak to Firestore for ${originalStudentState.id}: $e");
      if (mounted) {
        state = originalStudentState;
        print(
            "StudentDetailsNotifier: Reverted local XP and Streak due to Firestore save error for ${originalStudentState.id}.");
      }
    }
  }

  StudentModel _ensureStateExists(String uid, String email) {
    if (state == null || state!.id != uid) {
      print(
          "Notifier: State is null or for different user, initializing minimal student state for $uid");
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
          deviceInfo: {},
          coins: 0,
          dailyStreak: 0,
          lastXpEarnedDate: null // Initialize new field
          );
    }
    return state!;
  }

  // `fetchStudentDetails` was defined above, removed duplicate here.

  void setStudentDetails(StudentModel student) {
    if (mounted) state = student;
  }

  void setClass(String studentClass) {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    final currentState = _ensureStateExists(user.uid, user.email ?? "");
    if (mounted) state = currentState.copyWith(grade: studentClass);
    print("Notifier: Updated grade in state to $studentClass");
  }

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

  void updateEnrolledSubjects(List<String> subjects) {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      print("❌ Error: Cannot update subjects, user not logged in.");
      return;
    }
    final currentState = _ensureStateExists(user.uid, user.email ?? "");
    if (mounted) {
      state = currentState.copyWith(enrolledSubjects: subjects);
      print("Notifier: Updated subjects in state for ${user.uid}.");
    }
  }

  Future<void> saveStudentDataToFirestore() async {
    if (state == null) throw Exception("Student data is null, cannot save.");
    if (state!.id.isEmpty) throw Exception("Student ID is missing.");
    if (state!.grade.isEmpty ||
        (state!.board != null && state!.board!.isEmpty)) {
      // Allow board to be null but not empty string
      throw Exception(
          "Essential profile data (Grade/Board if provided) is missing.");
    }

    final dbService = _ref.read(studentDatabaseServiceProvider);
    try {
      print(
          "Notifier: Saving final student data to Firestore for ${state!.id}");
      Map<String, dynamic> studentData = state!.toJson();
      await dbService.setStudentData(state!.id, studentData);
      print("✅ Notifier: Student data saved successfully.");
    } catch (e) {
      print("❌ Notifier: Error saving student data: $e");
      rethrow;
    }
  }

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

  bool get isCurrentlyFetching => _isFetching;
  Object? get currentFetchError => _fetchError;
  StackTrace? get currentFetchStackTrace => _fetchStackTrace;
}
// --- End State Notifier ---

final studentDetailsNotifierProvider =
    StateNotifierProvider.autoDispose<StudentDetailsNotifier, StudentModel?>(
  (ref) {
    print(
        "studentDetailsNotifierProvider: Creating StudentDetailsNotifier instance.");
    return StudentDetailsNotifier(ref);
  },
);

final studentDetailsProvider =
    Provider.autoDispose<AsyncValue<StudentModel?>>((ref) {
  final studentModel = ref.watch(studentDetailsNotifierProvider);
  final authValue = ref.watch(authStateProvider);
  final notifier = ref.read(studentDetailsNotifierProvider.notifier);

  if (authValue is AsyncLoading) {
    print("studentDetailsProvider (AsyncValue): Auth is loading.");
    return const AsyncValue.loading();
  } else if (authValue is AsyncError) {
    print(
        "studentDetailsProvider (AsyncValue): Auth error: ${authValue.error}.");
    return AsyncValue.error(authValue.error!, authValue.stackTrace!);
  } else {
    final firebaseUser = authValue.valueOrNull;
    if (firebaseUser == null) {
      print(
          "studentDetailsProvider (AsyncValue): User logged out (authValue). studentModel is $studentModel");
      return AsyncValue.data(null);
    } else {
      if (notifier.isCurrentlyFetching && studentModel == null) {
        print(
            "studentDetailsProvider (AsyncValue): Logged in, initial fetch in progress for ${firebaseUser.uid}.");
        return const AsyncValue.loading();
      } else if (notifier.currentFetchError != null) {
        print(
            "studentDetailsProvider (AsyncValue): Fetch error for ${firebaseUser.uid}: ${notifier.currentFetchError}.");
        return AsyncValue.error(notifier.currentFetchError!,
            notifier.currentFetchStackTrace ?? StackTrace.current);
      } else {
        print(
            "studentDetailsProvider (AsyncValue): User logged in (${firebaseUser.uid}). studentModel: ${studentModel?.name}. isFetching: ${notifier.isCurrentlyFetching}");
        return AsyncValue.data(studentModel);
      }
    }
  }
});
