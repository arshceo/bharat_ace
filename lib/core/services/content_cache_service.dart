// lib/core/services/content_cache_service.dart (Example Structure)
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:shared_preferences/shared_preferences.dart';

class ContentCacheService {
  // Generates a unique key for caching
  String _getCacheKey(String subject, String chapter, String topic) {
    return 'content_${subject}_${chapter}_$topic'
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  Future<String?> getCachedContent(
      String subject, String chapter, String topic) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCacheKey(subject, chapter, topic);
    return prefs.getString(key);
  }

  Future<void> saveContentToCache(
      String subject, String chapter, String topic, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCacheKey(subject, chapter, topic);
    await prefs.setString(key, content);
    print("Content saved to cache for key: $key");
  }

  Future<void> clearCacheForTopic(
      String subject, String chapter, String topic) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCacheKey(subject, chapter, topic);
    await prefs.remove(key);
    print("Cache cleared for key: $key");
  }
}

// Provider for the cache service
final contentCacheServiceProvider = Provider<ContentCacheService>((ref) {
  return ContentCacheService();
});
