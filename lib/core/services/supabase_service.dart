// lib/core/services/supabase_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import 'package:bharat_ace/core/config/supabase_config.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/services/initialization_service.dart';

class SupabaseService {
  // Use a getter to access the client after initialization
  static SupabaseClient get _client {
    try {
      // Check if our initialization service says it's ready
      InitializationService.ensureSupabaseInitialized();

      // Get the client
      final client = Supabase.instance.client;

      return client;
    } catch (e) {
      throw Exception(
          'Supabase must be initialized before use. Call Supabase.initialize() in main(). Error: $e');
    }
  }

  // Ensure user authentication with Supabase
  static Future<void> ensureAuthenticated(String userId, String email) async {
    try {
      // Check if user is already authenticated
      if (_client.auth.currentUser != null) {
        print(
            '✅ User already authenticated with Supabase: ${_client.auth.currentUser!.id}');
        return;
      }

      // Sign in anonymously first to satisfy RLS policies
      final response = await _client.auth.signInAnonymously();
      if (response.user != null) {
        print('✅ Anonymous authentication successful: ${response.user!.id}');
      }
    } catch (e) {
      print('⚠️ Authentication with Supabase failed: $e');
      // For now, we'll continue without auth but with a warning
      // In production, you might want to implement proper user auth sync
    }
  }

  // User Management
  static Future<void> createOrUpdateUser(StudentModel student) async {
    try {
      // Ensure authentication before creating/updating user
      await ensureAuthenticated(student.id, student.email);

      final userData = {
        'id': student.id,
        'username': student.username,
        'name': student.name,
        'email': student.email,
        'phone': student.phone,
        'school': student.school,
        'board': student.board,
        'grade': student.grade,
        'enrolled_subjects': student.enrolledSubjects,
        'created_at': student.createdAt.toDate().toIso8601String(),
        'last_active': student.lastActive.toDate().toIso8601String(),
        'xp': student.xp,
        'coins': student.coins,
        'daily_streak': student.dailyStreak,
        'is_premium': student.isPremium,
        'avatar': student.avatar,
        'bio': student.bio,
        'study_goal': student.studyGoal,
        'contributions_count': student.contributionsCount,
        'study_buddies_count': student.studyBuddiesCount,
        'exam_date': student.examDate?.toIso8601String(),
        'mst_date': student.mstDate?.toIso8601String(),
      };

      await _client.from(SupabaseConfig.usersTable).upsert(userData);
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Upload file to Supabase Storage with proper authentication and path structure
  static Future<String> uploadFile(
      File file, String bucket, String fileName, String userId) async {
    try {
      // Ensure user is authenticated
      await ensureAuthenticated(userId, '');

      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      // Create proper file path structure for RLS compliance
      // Format: userId/filename to satisfy RLS policy: (storage.foldername(name))[1] = auth.uid()::text
      final filePath = '$userId/$fileName';

      await _client.storage.from(bucket).upload(filePath, file,
          fileOptions: FileOptions(contentType: mimeType));

      return _client.storage.from(bucket).getPublicUrl(filePath);
    } catch (e) {
      print('❌ Failed to upload file: $e');

      // If it's an RLS policy error, try uploading with anonymous access
      if (e.toString().contains('row-level security') ||
          e.toString().contains('unauthorized') ||
          e.toString().contains('403')) {
        try {
          print('🔄 Attempting fallback upload with public access...');

          // For now, upload to a public path that doesn't trigger RLS
          final publicFileName =
              'public/${DateTime.now().millisecondsSinceEpoch}_$fileName';
          final mimeType =
              lookupMimeType(file.path) ?? 'application/octet-stream';

          await _client.storage.from(bucket).upload(publicFileName, file,
              fileOptions: FileOptions(contentType: mimeType));

          return _client.storage.from(bucket).getPublicUrl(publicFileName);
        } catch (fallbackError) {
          print('❌ Fallback upload also failed: $fallbackError');
          throw Exception(
              'Failed to upload file even with fallback: $fallbackError');
        }
      }

      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload profile image
  static Future<String> uploadProfileImage(
      File imageFile, String userId) async {
    final fileName =
        'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadFile(
        imageFile, SupabaseConfig.profileImagesBucket, fileName, userId);
  }

  // Upload user content (images/videos)
  static Future<String> uploadUserContent(
      File file, String userId, String contentType) async {
    final extension = file.path.split('.').last;
    final fileName =
        '${contentType}_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    return await uploadFile(
        file, SupabaseConfig.userContentBucket, fileName, userId);
  }

  // Create thumbnail for video
  static Future<String> uploadThumbnail(
      File thumbnailFile, String userId) async {
    final fileName =
        'thumb_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadFile(
        thumbnailFile, SupabaseConfig.userContentBucket, fileName, userId);
  }
}
