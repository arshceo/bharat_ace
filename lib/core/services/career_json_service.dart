import 'dart:convert';
import 'package:flutter/services.dart';

class CareerJsonService {
  static Future<Map<String, dynamic>> loadCareersData() async {
    try {
      print('🧪 CAREER SERVICE ASSET TEST 🧪');

      // Try different possible paths
      final List<String> paths = [
        'assets/career_database.json',
        'assets/career/career_database.json',
      ];

      // Variable to store successfully loaded JSON data
      String? fileJsonData;
      String? successfulPath;

      // Try each path and use the first successful one
      for (String path in paths) {
        try {
          fileJsonData = await rootBundle.loadString(path);
          successfulPath = path;
          print('✅ Loaded from $path! Length: ${fileJsonData.length}');
          break; // Exit the loop once we successfully load a file
        } catch (e) {
          print('❌ Failed to load $path: $e');
        }
      }

      // If we successfully loaded a file, parse it and use it
      if (fileJsonData != null && fileJsonData.isNotEmpty) {
        try {
          final Map<String, dynamic> parsed = json.decode(fileJsonData);
          print(
              '✓ JSON parsed successfully with ${parsed.keys.length} top-level keys');

          if (parsed.containsKey('careers_database')) {
            final careers = parsed['careers_database'] as Map<String, dynamic>;
            print(
                '✓ Using data from $successfulPath with ${careers.length} careers');

            // Print some sample data for debugging
            final careerIds = careers.keys.toList();
            final sampleIds =
                careerIds.length > 3 ? careerIds.sublist(0, 3) : careerIds;
            print('Sample data: $sampleIds');

            // Print categories for debugging
            final categories = getCareerCategories(careers);
            print('Categories found: $categories');

            return careers;
          } else {
            throw Exception('No careers_database key found in JSON file');
          }
        } catch (parseError) {
          throw Exception('JSON parse failed: $parseError');
        }
      } else {
        throw Exception('No career data file could be loaded');
      }
    } catch (e) {
      print('Error loading career data: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to load career data: $e');
    }
  }

  // No fallback data - we'll rely solely on the JSON file

  static List<String> getCareerCategories(Map<String, dynamic> careersData) {
    final Set<String> categories = {};

    // Safety check for empty data
    if (careersData.isEmpty) {
      print('WARNING: Career data is empty when trying to get categories');
      return [];
    }

    try {
      careersData.forEach((key, career) {
        if (career is Map<String, dynamic> && career['category'] != null) {
          categories.add(career['category']);
        } else {
          print('WARNING: Career "$key" has no category or is malformed');
        }
      });
    } catch (e) {
      print('Error extracting career categories: $e');
      return [];
    }

    return categories.toList()..sort();
  }

  static Map<String, dynamic> filterCareersByCategory(
    Map<String, dynamic> careersData,
    String category,
  ) {
    if (category == 'All') {
      return careersData;
    }

    final Map<String, dynamic> filteredCareers = {};

    careersData.forEach((key, career) {
      if (career['category'] == category) {
        filteredCareers[key] = career;
      }
    });

    return filteredCareers;
  }

  static Map<String, dynamic> searchCareers(
    Map<String, dynamic> careersData,
    String query,
  ) {
    if (query.isEmpty) {
      return careersData;
    }

    final Map<String, dynamic> filteredCareers = {};
    final lowercaseQuery = query.toLowerCase();

    careersData.forEach((key, career) {
      final title = career['title']?.toString().toLowerCase() ?? '';

      // Check both description and shortDescription fields
      String description = '';
      if (career['description'] != null) {
        description = career['description'].toString().toLowerCase();
      } else if (career['shortDescription'] != null) {
        description = career['shortDescription'].toString().toLowerCase();
      } else if (career['longDescription'] != null) {
        description = career['longDescription'].toString().toLowerCase();
      }

      final category = career['category']?.toString().toLowerCase() ?? '';

      // Get the icon for additional search
      final icon = career['icon']?.toString().toLowerCase() ?? '';

      // Search in overview fields if they exist
      String overview = '';
      if (career['overview'] is Map) {
        final overviewMap = career['overview'] as Map<String, dynamic>;
        overview = overviewMap.values.join(' ').toLowerCase();
      }

      // Search in required skills if they exist
      String skills = '';
      if (career['required_skills'] is Map) {
        final requiredSkills =
            career['required_skills'] as Map<String, dynamic>;

        // Check technical skills
        if (requiredSkills['technical_skills'] is List) {
          for (var skill in requiredSkills['technical_skills']) {
            if (skill is Map) {
              skills += ' ' + (skill['skill']?.toString().toLowerCase() ?? '');
              if (skill['details'] is List) {
                skills +=
                    ' ' + (skill['details'] as List).join(' ').toLowerCase();
              }
            }
          }
        }

        // Check soft skills
        if (requiredSkills['soft_skills'] is List) {
          for (var skill in requiredSkills['soft_skills']) {
            if (skill is Map) {
              skills += ' ' + (skill['skill']?.toString().toLowerCase() ?? '');
            }
          }
        }
      }

      if (title.contains(lowercaseQuery) ||
          description.contains(lowercaseQuery) ||
          category.contains(lowercaseQuery) ||
          icon.contains(lowercaseQuery) ||
          overview.contains(lowercaseQuery) ||
          skills.contains(lowercaseQuery)) {
        filteredCareers[key] = career;
      }
    });

    return filteredCareers;
  }
}
