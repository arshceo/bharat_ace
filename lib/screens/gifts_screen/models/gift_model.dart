import 'package:flutter/material.dart'; // For IconData

class Gift {
  final String id;
  final String name;
  final String description;
  final int xpRequired;
  final int consistencyDaysRequired;
  final int testsRequired; // Total tests needed for this gift path
  final IconData icon; // Placeholder for actual gift image/asset
  final String LottieAnimationUrl; // For locked/unlocked gift pod animation
  final List<String> videoUrls; // For "what you can do" videos
  final int? estimatedCost; // Optional: to store cost from JSON
  Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.xpRequired,
    required this.consistencyDaysRequired,
    required this.testsRequired,
    required this.icon,
    this.LottieAnimationUrl =
        "assets/animations/default_gift_pod.json", // Default
    required this.videoUrls,
    this.estimatedCost,
  });

  // Add copyWith, fromJson, toJson if needed for persistence/API
}
