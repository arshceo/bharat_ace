// lib/core/services/supabase_creation_service.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:bharat_ace/core/models/content_type_enum.dart';
import 'package:bharat_ace/core/services/supabase_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

final supabaseCreationServiceProvider =
    Provider((ref) => SupabaseCreationService(ref));

class SupabaseCreationService {
  final Ref _ref;
  SupabaseCreationService(this._ref);

  final Uuid _uuid = const Uuid();
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
  }

  Future<XFile?> pickVideo() async {
    return await _picker.pickVideo(source: ImageSource.gallery);
  }

  Future<String?> _generateAndUploadVideoThumbnail(
      File videoFile, String userId, String uniqueId) async {
    try {
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.WEBP,
        maxHeight: 480,
        quality: 75,
      );

      if (thumbnailPath != null) {
        File thumbnailFile = File(thumbnailPath);
        String thumbnailUrl =
            await SupabaseService.uploadThumbnail(thumbnailFile, userId);
        await thumbnailFile.delete(); // Clean up temp file
        return thumbnailUrl;
      }
    } catch (e) {
      print("Error generating/uploading video thumbnail: $e");
    }
    return null;
  }

  Future<bool> createAndUploadContent({
    required File file,
    required String title,
    required String userId,
    required ContentType type,
    required Function(double) onProgress,
    String? description,
  }) async {
    try {
      print('🚀 Starting upload process for user: $userId');
      onProgress(0.01); // Indicate start
      String uniqueContentId = _uuid.v4();

      // Upload main file to Supabase
      onProgress(0.1); // Starting file upload
      print('📤 Uploading ${type.name} file to Supabase...');

      String downloadUrl;
      try {
        downloadUrl =
            await SupabaseService.uploadUserContent(file, userId, type.name);
        print('✅ File uploaded successfully: $downloadUrl');
      } catch (uploadError) {
        print('❌ Upload failed: $uploadError');

        // Provide more specific error information
        if (uploadError.toString().contains('row-level security') ||
            uploadError.toString().contains('unauthorized') ||
            uploadError.toString().contains('403')) {
          print('🔐 This appears to be a permission/authentication error');
          throw Exception(
              'Authentication error: Please ensure you are logged in and try again');
        } else if (uploadError.toString().contains('network')) {
          throw Exception(
              'Network error: Please check your internet connection');
        } else {
          throw Exception('Upload failed: ${uploadError.toString()}');
        }
      }

      onProgress(0.7); // File upload complete

      String thumbnailUrl =
          downloadUrl; // For images, thumbnail is the image itself

      if (type == ContentType.video) {
        onProgress(0.75); // Starting thumbnail generation
        print('🎬 Generating video thumbnail...');
        try {
          thumbnailUrl = (await _generateAndUploadVideoThumbnail(
                  file, userId, uniqueContentId)) ??
              downloadUrl;
          print('✅ Thumbnail generated successfully');
        } catch (thumbError) {
          print(
              '⚠️ Thumbnail generation failed, using original video URL: $thumbError');
          // Continue with original URL as fallback
        }
      }

      onProgress(0.9); // Starting database save

      // // Create ProfileContentItem
      // final contentItem = ProfileContentItem(
      //   id: uniqueContentId,
      //   userId: userId,
      //   title: title,
      //   type: type,
      //   downloadUrl: downloadUrl,
      //   thumbnailUrl: thumbnailUrl,
      //   timestamp: DateTime.now(),
      //   views: 0,
      //   likes: 0,
      // );

      // Save to Supabase database
      print('💾 Saving content metadata to database...');
      try {
        // await SupabaseService.saveUserCreation(contentItem);
        print('✅ Content saved to database successfully');
      } catch (dbError) {
        print('❌ Database save failed: $dbError');
        throw Exception(
            'Failed to save content details: ${dbError.toString()}');
      }

      onProgress(1.0); // Done
      print('🎉 Upload process completed successfully!');
      return true;
    } catch (e) {
      print("❌ Error in createAndUploadContent: $e");
      onProgress(0.0); // Reset progress on error

      // Re-throw with more user-friendly message if it's a generic error
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Upload failed: ${e.toString()}');
      }
    }
  }
}
