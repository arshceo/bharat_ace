// lib/core/providers/student_subject_progress_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharat_ace/core/models/progress_models.dart';
import 'package:bharat_ace/core/providers/auth_provider.dart'; // For student UID

final studentSubjectProgressProvider = FutureProvider.autoDispose
    .family<SubjectProgress, String>((ref, subjectKey) async {
  // subjectKey is the specific subject or sub-subject ID (e.g., "Computer Science").
  // This key MUST match the document ID in Firestore under studentProgress/{uid}/progressData/

  final userAsyncValue = ref.watch(authStateProvider);
  final user = userAsyncValue.asData?.value;

  if (user == null || user.uid.isEmpty) {
    print(
        "StudentSubjectProgressProvider($subjectKey): No authenticated user or UID is empty. Returning default progress.");
    return SubjectProgress(chapters: {}); // Return default empty progress
  }

  if (subjectKey.isEmpty) {
    print(
        "StudentSubjectProgressProvider($subjectKey): subjectKey is empty. Returning empty progress.");
    return SubjectProgress(chapters: {});
  }

  final studentId = user.uid; // Directly use UID from authenticated user

  try {
    // CORRECTED Path: studentProgress/{studentId}/progressData/{subjectKey_document_id}
    final subjectProgressDocRef = FirebaseFirestore.instance
        .collection('studentProgress') // CORRECTED: Matches screenshot
        .doc(studentId)
        .collection('progressData') // CORRECTED: Matches screenshot
        .doc(subjectKey); // subjectKey is the document ID here

    final docSnapshot = await subjectProgressDocRef.get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      final data = docSnapshot.data()!;
      // SubjectProgress.fromMap expects the data map of the subject document.
      print(
          "StudentSubjectProgressProvider($subjectKey): Fetched progress for student '$studentId'. Chapters map: ${data['chapters'] != null}");
      return SubjectProgress.fromMap(data); // Pass the document's data map
    } else {
      print(
          "StudentSubjectProgressProvider($subjectKey): No progress document found for student '$studentId'. Path: ${subjectProgressDocRef.path}. Returning default empty progress.");
      return SubjectProgress(chapters: {});
    }
  } catch (e, stack) {
    print(
        "❌ StudentSubjectProgressProvider($subjectKey): Error fetching SubjectProgress for student '$studentId': $e\n$stack");
    return SubjectProgress(chapters: {}); // Fallback on error
  }
});
