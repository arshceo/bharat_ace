// lib/core/models/daily_feed_item.dart
import 'package:flutter/material.dart'; // For IconData and Color

enum DailyFeedItemType {
  quickTip, // For general study tips, smart study, learn fast
  motivationalQuote,
  funFact,
  healthWellnessTip, // New type for health
  lifeBalanceTip, // New type for enjoying life
  studyStrategy, // More specific than quickTip for deeper strategies
  learningTechnique, // For specific techniques like Feynman
}

class DailyFeedItem {
  final DailyFeedItemType type;
  final String title;
  final String content;
  final IconData icon;
  final Color? iconColor; // Making it nullable to use default if not specified

  DailyFeedItem({
    required this.type,
    required this.title,
    required this.content,
    required this.icon,
    this.iconColor,
  });
}
