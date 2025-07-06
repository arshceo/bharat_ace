// lib/core/utils/supabase_test.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SupabaseTest {
  static void testConnection() {
    try {
      final client = Supabase.instance.client;
      print('✅ Supabase client accessible and ready: ${client.toString()}');
      print('🔗 Supabase client initialized successfully');
      print(
          '👤 Current user: ${client.auth.currentUser?.id ?? 'No user authenticated'}');
    } catch (e) {
      print('❌ Supabase client error: $e');
    }
  }

  static Future<void> testAuthentication() async {
    try {
      final client = Supabase.instance.client;

      print('🔐 Testing Supabase authentication...');

      // Check current user
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        print('✅ User already authenticated: ${currentUser.id}');
        return;
      }

      // Try anonymous sign in
      print('🔄 Attempting anonymous sign in...');
      final response = await client.auth.signInAnonymously();

      if (response.user != null) {
        print('✅ Anonymous authentication successful!');
        print('👤 User ID: ${response.user!.id}');
        print('📧 User email: ${response.user!.email ?? 'No email'}');
      } else {
        print('❌ Anonymous authentication failed - no user returned');
      }
    } catch (e) {
      print('❌ Authentication test failed: $e');
    }
  }

  static Future<void> testStorageUpload() async {
    try {
      final client = Supabase.instance.client;

      // Ensure we're authenticated first
      await testAuthentication();

      print('📤 Testing storage upload...');

      // Create a small test file
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/test_upload.txt');
      await testFile.writeAsString('This is a test file for Supabase upload');

      // Try to upload
      final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';

      // First try with user-specific path
      try {
        final currentUser = client.auth.currentUser;
        String uploadPath;

        if (currentUser != null) {
          uploadPath = '${currentUser.id}/$fileName';
          print('📁 Uploading to user-specific path: $uploadPath');
        } else {
          uploadPath = 'public/$fileName';
          print('📁 Uploading to public path: $uploadPath');
        }

        await client.storage.from('user-content').upload(uploadPath, testFile);

        final publicUrl =
            client.storage.from('user-content').getPublicUrl(uploadPath);

        print('✅ Upload successful!');
        print('🔗 Public URL: $publicUrl');

        // Clean up test file
        await testFile.delete();

        // Optionally delete the uploaded file too
        await client.storage.from('user-content').remove([uploadPath]);
        print('🗑️ Test file cleaned up');
      } catch (uploadError) {
        print('❌ Upload failed: $uploadError');

        // Try fallback upload
        print('🔄 Trying fallback upload to public folder...');
        try {
          final fallbackPath = 'public/$fileName';
          await client.storage
              .from('user-content')
              .upload(fallbackPath, testFile);

          print('✅ Fallback upload successful!');

          // Clean up
          await testFile.delete();
          await client.storage.from('user-content').remove([fallbackPath]);
          print('🗑️ Fallback test file cleaned up');
        } catch (fallbackError) {
          print('❌ Fallback upload also failed: $fallbackError');
        }
      }
    } catch (e) {
      print('❌ Storage test failed: $e');
    }
  }

  static Future<void> runAllTests() async {
    print('🧪 Starting Supabase tests...');
    print('=' * 50);

    testConnection();
    print('-' * 30);

    await testAuthentication();
    print('-' * 30);

    await testStorageUpload();
    print('-' * 30);

    print('🏁 All tests completed!');
  }
}
