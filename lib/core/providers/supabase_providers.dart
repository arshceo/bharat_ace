// lib/core/providers/supabase_providers.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/services/supabase_service.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';

// Provider for uploading profile image
final profileImageUploadProvider =
    FutureProvider.family<String, File>((ref, imageFile) async {
  final student = ref.watch(studentDetailsProvider).valueOrNull;
  if (student == null) throw Exception('User not authenticated');

  try {
    return await SupabaseService.uploadProfileImage(imageFile, student.id);
  } catch (e) {
    print('Error uploading profile image: $e');
    rethrow;
  }
});

// Provider for syncing user to Supabase
final syncUserToSupabaseProvider =
    FutureProvider.family<void, StudentModel>((ref, student) async {
  return await SupabaseService.createOrUpdateUser(student);
});
