// lib/core/services/syllabus_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
// Optional: If loading from Firestore
import 'package:bharat_ace/core/models/syllabus_models.dart';

class SyllabusService {
  // Option 1: Load from JSON (Simpler for initial setup, harder to query dependencies)
  Future<Syllabus> getClassSyllabusFromJson(
      String className, String board) async {
    final String filePath =
        'assets/syllabus/class_${className}_${board.toLowerCase()}.json';
    print("SyllabusService: Loading syllabus JSON from: $filePath");
    try {
      final String response = await rootBundle.loadString(filePath);
      final Map<String, dynamic> data = json.decode(response);
      // Validate essential keys before parsing
      if (!data.containsKey('subjects') ||
          data['subjects'] is! Map ||
          !data.containsKey('class') ||
          !data.containsKey('board')) {
        throw Exception("Invalid root structure in syllabus JSON: $filePath");
      }
      final syllabus = Syllabus.fromJson(data); // Use the model's factory
      print(
          "SyllabusService: Parsed syllabus JSON successfully for ${syllabus.className} ${syllabus.board}.");
      return syllabus;
    } catch (e, stack) {
      print(
          "❌ SyllabusService Error loading/parsing syllabus JSON from $filePath: $e");
      print(stack); // Print stacktrace for debugging
      throw Exception(
          "Failed to load or parse syllabus for Class $className $board.");
    }
  }

  // Option 2: Load from Firestore (More complex setup, better querying later)
  // Future<Syllabus> getClassSyllabusFromFirestore(String grade, String board) async {
  //   final String docId = 'class_${grade}_${board.toLowerCase()}';
  //   final docSnap = await FirebaseFirestore.instance.collection('syllabi').doc(docId).get();
  //   if (docSnap.exists && docSnap.data() != null) {
  //     return Syllabus.fromJson(docSnap.data()!); // Assuming model handles Firestore map
  //   } else {
  //     throw Exception("Syllabus document not found in Firestore: $docId");
  //   }
  // }
}
