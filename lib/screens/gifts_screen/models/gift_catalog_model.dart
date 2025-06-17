import 'package:bharat_ace/screens/gifts_screen/models/gift_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For @required

// Model for individual gift items from JSON
class CatalogGiftItem {
  final int id; // JSON id is int
  final String giftItem;
  final int estimatedCostInr;
  final String description;

  CatalogGiftItem({
    required this.id,
    required this.giftItem,
    required this.estimatedCostInr,
    required this.description,
  });

  factory CatalogGiftItem.fromJson(Map<String, dynamic> json) {
    return CatalogGiftItem(
      id: json['id'] as int,
      giftItem: json['gift_item'] as String,
      estimatedCostInr: json['estimated_cost_inr'] as int,
      description: json['description'] as String,
    );
  }

  // We need to convert this CatalogGiftItem to your existing Gift model
  // You'll need to decide how to map JSON fields to your Gift model's requirements
  // (xpRequired, consistencyDaysRequired, testsRequired, icon, videoUrls etc.)
  // For now, let's make some assumptions.
  Gift toAppGiftModel({
    required int xpRequired,
    required int consistencyDaysRequired,
    required int testsRequired,
    required IconData iconData,
    // IconData icon, // You'll need a strategy for icons
    String? LottieAnimationUrl, // And Lottie animations
    List<String>? videoUrls,
  }) {
    return Gift(
      id: 'catalog_gift_${id}', // Create a unique string ID for the app's Gift model
      name: giftItem,
      description: description,
      xpRequired:
          xpRequired, // These will need to be defined, perhaps based on phase or cost
      consistencyDaysRequired: consistencyDaysRequired,
      testsRequired: testsRequired,
      icon: iconData, // Placeholder icon
      // LottieAnimationUrl: LottieAnimationUrl ?? "assets/animations/default_gift_pod.json",
      videoUrls: videoUrls ?? [],
      // Add other fields like estimatedCost if you want to display it
      estimatedCost: estimatedCostInr,
    );
  }
}

class GiftPhase {
  final String phaseName;
  final List<CatalogGiftItem> gifts;
  final int totalEstimatedCostPhaseInr;

  GiftPhase({
    required this.phaseName,
    required this.gifts,
    required this.totalEstimatedCostPhaseInr,
  });

  factory GiftPhase.fromJson(Map<String, dynamic> json) {
    var giftList = json['gifts'] as List;
    List<CatalogGiftItem> gifts =
        giftList.map((i) => CatalogGiftItem.fromJson(i)).toList();

    return GiftPhase(
      phaseName: json['phase_name'] as String,
      gifts: gifts,
      totalEstimatedCostPhaseInr: json['total_estimated_cost_phase_inr'] as int,
    );
  }
}

class GiftCatalog {
  final String title;
  final List<GiftPhase> phases;
  final int overallTotalEstimatedCostInr;

  GiftCatalog({
    required this.title,
    required this.phases,
    required this.overallTotalEstimatedCostInr,
  });

  factory GiftCatalog.fromJson(Map<String, dynamic> json) {
    var phaseList = json['phases'] as List;
    List<GiftPhase> phases =
        phaseList.map((i) => GiftPhase.fromJson(i)).toList();

    return GiftCatalog(
      title: json['title'] as String,
      phases: phases,
      overallTotalEstimatedCostInr:
          json['overall_total_estimated_cost_inr'] as int,
    );
  }
}
