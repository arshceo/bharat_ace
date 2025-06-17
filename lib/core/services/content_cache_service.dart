// lib/core/services/content_cache_service.dart (Example Structure)
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:shared_preferences/shared_preferences.dart';

class ContentCacheService {
  // Generates a unique key for caching
  // String _getCacheKey(String subject, String chapter, String topic) {
  //   return 'content_${subject}_${chapter}_$topic'
  //       .replaceAll(' ', '_')
  //       .toLowerCase();
  // }

  Future<String?> getCachedContent(
      String cacheKey // MODIFIED: Accept the pre-computed cacheKey directly
      ) async {
    final prefs = await SharedPreferences.getInstance();
    print("ContentCacheService: Attempting to get from cacheKey: $cacheKey");
    return prefs.getString(cacheKey);
  }

  Future<void> saveContentToCache(
      String cacheKey, // MODIFIED: Accept the pre-computed cacheKey directly
      String content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, content);
    print("ContentCacheService: Content saved to cache for key: $cacheKey");
  }

  Future<void> clearCacheForTopic(
      String cacheKey // MODIFIED: Accept the pre-computed cacheKey directly
      ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
    print("ContentCacheService: Cache cleared for key: $cacheKey");
  }
}

// Provider for the cache service
final contentCacheServiceProvider = Provider<ContentCacheService>((ref) {
  return ContentCacheService();
});
