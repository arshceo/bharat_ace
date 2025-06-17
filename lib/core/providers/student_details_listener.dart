// lib/core/providers/student_details_listener.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';

final studentDetailsFetcher = Provider<void>((ref) {
  // Minimal logging in production
  // print("ℹ️ Initializing studentDetailsFetcher listener.");
  ref.listen<AsyncValue<User?>>(authStateProvider,
      (previousAuthState, currentAuthState) {
    final notifier = ref.read(studentDetailsNotifierProvider.notifier);
    final User? currentUser = currentAuthState.valueOrNull;
    if (currentUser != null) {
      final AsyncValue<StudentModel?> currentStudentData =
          ref.read(studentDetailsProvider);
      final StudentModel? student = currentStudentData.valueOrNull;
      if (student == null || student.id != currentUser.uid) {
        notifier.fetchStudentDetails();
      }
    } else {
      notifier.clearStudentDetails();
    }
  });
}, name: 'studentDetailsFetcher');
