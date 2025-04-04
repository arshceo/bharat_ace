import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/models/chapter_model.dart';

class JSONLoader {
  static Future<List<Chapter>> loadChapters(
      String className, String subject) async {
    try {
      // Load JSON file
      final String response =
          await rootBundle.loadString('assets/data/class_8.json');
      final Map<String, dynamic> data = json.decode(response);

      // Check if subjects exist
      if (!data.containsKey('subjects')) {
        throw Exception("Missing 'subjects' key in JSON.");
      }

      final subjects = data['subjects'];

      // Check if the subject exists
      if (!subjects.containsKey(subject)) {
        throw Exception("Subject '$subject' not found in JSON.");
      }

      // Extract chapters based on subject type
      var subjectData = subjects[subject];

      List<String> chaptersList = [];

      if (subjectData is Map) {
        // Handle subjects like "Social Science" which have subcategories (History, Geography, etc.)
        subjectData.forEach((subCategory, chapterArray) {
          if (chapterArray is List) {
            chaptersList.addAll(chapterArray.cast<String>());
          }
        });
      } else if (subjectData is List) {
        // Normal subjects like Mathematics, Science, English, etc.
        chaptersList = subjectData.cast<String>();
      }

      // Convert to List<Chapter>
      return chaptersList
          .map((title) => Chapter(title: title, unlocked: true, progress: 0))
          .toList();
    } catch (e) {
      print("❌ Error loading chapters: $e");
      return [];
    }
  }
}
