import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:bharat_ace/core/models/content_type_enum.dart'; // Your enum
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

final creationServiceProvider = Provider((ref) => CreationService(ref));

class CreationService {
  final Ref _ref; // For reading other providers if needed
  CreationService(this._ref);

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
  }

  Future<XFile?> pickVideo() async {
    return await _picker.pickVideo(source: ImageSource.gallery);
  }

  Future<String?> _uploadFileToStorage(File file, String userId,
      ContentType type, String uniqueId, Function(double) onProgress) async {
    try {
      String fileExtension = file.path.split('.').last.toLowerCase();
      String fileName = '$uniqueId.$fileExtension'; // Use passed uniqueId
      String path = 'user_creations/$userId/${type.name}/$fileName';

      UploadTask uploadTask = _storage.ref().child(path).putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading file to Storage: $e");
      return null;
    }
  }

  Future<String?> _generateAndUploadVideoThumbnail(File videoFile,
      String userId, String uniqueId, Function(double) onProgress) async {
    try {
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.WEBP,
        maxHeight: 480, // Adjust for quality/size
        quality: 75,
      );

      if (thumbnailPath != null) {
        File thumbnailFile = File(thumbnailPath);
        // Use a different onProgress for thumbnail or simplify
        String? thumbnailUrl = await _uploadFileToStorage(
            thumbnailFile,
            userId,
            ContentType.image,
            '${uniqueId}_thumb',
            (p) {}); // Simplified progress for thumb
        await thumbnailFile.delete(); // Clean up temp thumbnail file
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
    required Function(double) onProgress, // Overall progress for UI
    String? description,
  }) async {
    try {
      onProgress(0.01); // Indicate start
      String uniqueContentId =
          _uuid.v4(); // Unique ID for content and its files

      String? downloadUrl = await _uploadFileToStorage(
          file, userId, type, uniqueContentId, (storageProgress) {
        // Scale storage progress (e.g., it takes 80% of the overall progress)
        onProgress(0.01 + (storageProgress * 0.8));
      });

      if (downloadUrl == null) return false;

      String thumbnailUrl =
          downloadUrl; // For images, thumbnail is the image itself

      if (type == ContentType.video) {
        onProgress(0.81); // Indicate thumbnail generation start
        thumbnailUrl = (await _generateAndUploadVideoThumbnail(
                file, userId, uniqueContentId, (p) {})) ??
            downloadUrl; // Fallback
      }
      onProgress(0.90); // Indicate Firestore save start

      // Save metadata to Firestore
      await _firestore.collection('userCreations').doc(uniqueContentId).set({
        'id': uniqueContentId,
        'userId': userId,
        'title': title,
        'description': description ?? '',
        'downloadUrl': downloadUrl,
        'thumbnailUrl': thumbnailUrl,
        'contentType': type.name,
        'timestamp': FieldValue.serverTimestamp(),
        'views': 0,
        'likes': 0,
      });

      // Update student's contributionsCount
      await _firestore.collection('students').doc(userId).update({
        'contributionsCount': FieldValue.increment(1),
      });
      onProgress(1.0); // Done
      return true;
    } catch (e) {
      print("Error in createAndUploadContent: $e");
      onProgress(0.0); // Reset progress on error
      return false;
    }
  }
}
