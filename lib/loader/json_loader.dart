// lib/loader/json_loader.dart
import 'dart:convert';
// import 'package:bharat_ace/core/models/chapter_model.dart' show Chapter;
import 'package:flutter/services.dart';
// Import models IF the loader creates model instances directly
// import '../core/models/chapter_model.dart';
// import '../core/models/subject_model.dart';

class JSONLoader {
  // *** Keep only loadClassSyllabus, returning the RAW map ***
  static Future<Map<String, dynamic>> loadClassSyllabus(
      String className, String board) async {
    // Use board in the filename convention
    final String filePath =
        'assets/data/class_${className}_${board.toLowerCase()}.json';
    print("JSONLoader: Attempting to load syllabus from: $filePath");
    try {
      final String response = await rootBundle.loadString(filePath);
      final Map<String, dynamic> data = json.decode(response);
      // No need to validate 'subjects' here, provider will handle parsing
      print(
          "JSONLoader: Raw syllabus data loaded for class $className, board $board.");
      return data; // Return the full raw map including class/board info
    } catch (e) {
      print("❌ Error loading/parsing syllabus from $filePath: $e");
      rethrow;
    }
  }
}
