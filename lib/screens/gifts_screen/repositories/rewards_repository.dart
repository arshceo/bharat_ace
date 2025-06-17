import 'dart:convert'; // For json.decode
import 'package:flutter/services.dart'
    show PlatformException, rootBundle; // For loading assets
import 'package:flutter/material.dart'; // For Icons
// Adjust import paths based on your project structure
import 'package:bharat_ace/screens/gifts_screen/models/gift_catalog_model.dart';
import 'package:bharat_ace/screens/gifts_screen/models/gift_model.dart';
import 'package:bharat_ace/screens/gifts_screen/models/student_progress_model.dart';

class RewardsRepository {
  // Method to determine XP, consistency, etc., based on gift or phase
  // This is a placeholder logic. You'll need to define how these are set.
  Map<String, dynamic> _getAppGiftParameters(
      CatalogGiftItem catalogGift, String phaseName) {
    int xp;
    int consistency;
    int tests;

    // Example logic: Difficulty increases with phase and cost
    if (phaseName.toLowerCase().contains("phase 1")) {
      xp = 500 + (catalogGift.estimatedCostInr ~/ 3);
      consistency = 7 + (catalogGift.estimatedCostInr ~/ 150);
      tests = 2 + (catalogGift.estimatedCostInr ~/ 250);
    } else if (phaseName.toLowerCase().contains("phase 2")) {
      xp = 1200 + (catalogGift.estimatedCostInr ~/ 2);
      consistency = 14 + (catalogGift.estimatedCostInr ~/ 100);
      tests = 4 + (catalogGift.estimatedCostInr ~/ 180);
    } else {
      // Default for other phases if any
      xp = 800 + (catalogGift.estimatedCostInr ~/ 2.5).toInt();
      consistency = 10 + (catalogGift.estimatedCostInr ~/ 120);
      tests = 3 + (catalogGift.estimatedCostInr ~/ 200);
    }

    // Clamp values to reasonable mins/maxs if needed
    xp = xp.clamp(300, 10000);
    consistency = consistency.clamp(5, 60);
    tests = tests.clamp(1, 20);

    return {
      'xpRequired': xp,
      'consistencyDaysRequired': consistency,
      'testsRequired': tests,
      'iconData':
          _getIconForGift(catalogGift.giftItem), // Helper to get an icon
      // 'LottieAnimationUrl': "assets/animations/${catalogGift.id}.json", // If you have per-gift Lottie
      'videoUrls':
          <String>[], // Populate this if you have video URLs for catalog gifts
    };
  }

  IconData _getIconForGift(String giftName) {
    String lowerCaseName = giftName.toLowerCase();
    if (lowerCaseName.contains("science") ||
        lowerCaseName.contains("experiment")) {
      return Icons.science_outlined;
    } else if (lowerCaseName.contains("map") ||
        lowerCaseName.contains("geography")) {
      return Icons.map_outlined;
    } else if (lowerCaseName.contains("kaleidoscope") ||
        lowerCaseName.contains("light")) {
      return Icons.flare_outlined;
    } else if (lowerCaseName.contains("arduino") ||
        lowerCaseName.contains("electronics") ||
        lowerCaseName.contains("gadget")) {
      return Icons.memory_outlined;
    } else if (lowerCaseName.contains("course")) {
      return Icons.school_outlined;
    } else if (lowerCaseName.contains("robot")) {
      return Icons.smart_toy_outlined;
    }
    return Icons.card_giftcard_outlined; // Default
  }

  Future<List<Gift>> fetchAvailableGifts(String studentClass) async {
    String baseFilePath = 'assets/gifts/';
    String fileName;

    switch (studentClass) {
      case '6':
        fileName = 'class_6th_gifts.json';
        break;
      default:
        print(
            "Warning: Gift data for class $studentClass not found. Using default (Class 6).");
        fileName = 'class_6th_gifts.json';
    }
    String filePath = '$baseFilePath$fileName';

    String? fileContent; // Variable to hold content

    try {
      print("Attempting to load asset: $filePath");
      fileContent = await rootBundle.loadString(filePath); // Try to load first
      print(
          "SUCCESS: Asset '$filePath' loaded. Content length: ${fileContent.length}");
    } on PlatformException catch (e) {
      // Catch specific asset loading errors
      print(
          "AssetLoadingError: Failed to load asset '$filePath'. PlatformException: ${e.message}");
      print("Stacktrace: ${e.stacktrace}");
      return [
        Gift(
            id: 'error_asset_load',
            name: "Asset Loading Failed",
            description:
                "Could not find or access gift data file: $filePath. Details: ${e.message}",
            xpRequired: 99999,
            consistencyDaysRequired: 999,
            testsRequired: 99,
            icon: Icons.error_outline,
            videoUrls: []),
      ];
    } catch (e, stacktrace) {
      // Catch other generic errors during loading
      print("GenericAssetError: Failed to load asset '$filePath'. Error: $e");
      print("Stacktrace: $stacktrace");
      return [
        Gift(
            id: 'error_asset_generic',
            name: "Asset Error",
            description:
                "Unexpected error loading gift data file: $filePath. Error: $e",
            xpRequired: 99999,
            consistencyDaysRequired: 999,
            testsRequired: 99,
            icon: Icons.error_outline,
            videoUrls: []),
      ];
    }

    try {
      print("Attempting to parse JSON from '$filePath'");
      final data = json.decode(fileContent) as Map<String, dynamic>;
      print("SUCCESS: JSON parsed from '$filePath'");
      final giftCatalog = GiftCatalog.fromJson(data);
      print("SUCCESS: GiftCatalog created from JSON for '$filePath'");

      List<Gift> appGifts = [];
      for (var phase in giftCatalog.phases) {
        for (var catalogGift in phase.gifts) {
          final params = _getAppGiftParameters(catalogGift, phase.phaseName);
          // Add a print here to see what's being passed to toAppGiftModel
          // print("Params for ${catalogGift.giftItem}: $params");
          appGifts.add(catalogGift.toAppGiftModel(
            xpRequired: params['xpRequired'],
            consistencyDaysRequired: params['consistencyDaysRequired'],
            testsRequired: params['testsRequired'],
            iconData: params['iconData'],
            videoUrls: params['videoUrls'],
          ));
        }
      }
      print("SUCCESS: All gifts converted to AppGiftModel for '$filePath'");
      appGifts.sort((a, b) => a.xpRequired.compareTo(b.xpRequired));
      return appGifts;
    } catch (e, stacktrace) {
      print(
          "JSONParsingError: Failed to parse JSON or create models from '$filePath'. Error: $e");
      print("Stacktrace: $stacktrace");
      return [
        Gift(
            id: 'error_json_parse',
            name: "Data Parsing Error",
            description:
                "Could not parse gift data from file: $filePath. Ensure JSON is valid and matches models. Error: $e",
            xpRequired: 99999,
            consistencyDaysRequired: 999,
            testsRequired: 99,
            icon: Icons.error_outline,
            videoUrls: []),
      ];
    }
  }

  Future<void> updateStudentProgress(StudentProgress progress) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print(
        "Student progress updated (simulated): XP: ${progress.currentXp}, Streak: ${progress.consistencyStreakDays}, Tests: ${progress.completedTestsPerGiftPath}, Claimed Gifts: ${progress.claimedGiftIds}"); // MODIFIED for logging
  }

  // When fetching initial student progress, ensure claimedGiftIds is loaded if persisted
  Future<StudentProgress> fetchStudentProgress(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would come from a backend or local storage
    return StudentProgress(
      studentId: studentId,
      currentXp: 150,
      consistencyStreakDays: 2,
      completedTestsPerGiftPath: {},
      claimedGiftIds: {}, // Initialize with an empty set or load from persistence
    );
  }
}
