// lib/core/models/profile_content_item_model.dart (or similar)
import 'package:bharat_ace/core/models/content_type_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileContentItem {
  final String id;
  final String thumbnailUrl; // URL for the image/video thumbnail
  final String downloadUrl; // URL for the full image/video file
  final String title;
  final ContentType type;
  final String userId;
  final DateTime timestamp;
  final int views;
  final int likes;

  ProfileContentItem({
    required this.id,
    required this.thumbnailUrl,
    required this.downloadUrl,
    required this.title,
    required this.type,
    required this.userId,
    required this.timestamp,
    this.views = 0,
    this.likes = 0,
  });

  factory ProfileContentItem.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    ContentType type;
    switch (data['contentType'] as String?) {
      case 'video':
        type = ContentType.video;
        break;
      case 'image':
      default:
        type = ContentType.image;
        break;
    }
    return ProfileContentItem(
      id: documentId,
      title: data['title'] as String? ?? 'No Title',
      thumbnailUrl: data['thumbnailUrl'] as String? ??
          data['downloadUrl'] as String? ??
          '', // Fallback
      downloadUrl: data['downloadUrl'] as String? ?? '',
      type: type,
      userId: data['userId'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      views: data['views'] as int? ?? 0,
      likes: data['likes'] as int? ?? 0,
    );
  }
}
