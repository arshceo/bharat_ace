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

      // If we successfully loaded a file, try to parse and use it
      if (fileJsonData != null && fileJsonData.isNotEmpty) {
        try {
          final Map<String, dynamic> parsed = json.decode(fileJsonData);
          print(
              '✓ JSON parsed successfully with ${parsed.keys.length} top-level keys');

          if (parsed.containsKey('careers_database')) {
            final careers = parsed['careers_database'] as Map<String, dynamic>;
            print(
                '✓ Using data from $successfulPath with ${careers.length} careers');
            return careers;
          } else {
            print('⚠️ No careers_database key found in JSON from file');
            // Fall back to hardcoded data
          }
        } catch (parseError) {
          print('⚠️ JSON parse failed: $parseError');
          // Fall back to hardcoded data
        }
      } else {
        print('⚠️ No file successfully loaded, falling back to hardcoded data');
      }

      // If we reach here, we couldn't load from file or parse it successfully
      return _getFallbackCareerData();
    } catch (e) {
      print('Error loading career data: $e');
      print('Stack trace: ${StackTrace.current}');
      return _getFallbackCareerData();
    }
  }

  // Fallback data structured like the JSON file
  static Map<String, dynamic> _getFallbackCareerData() {
    print('Using fallback career data (FORMATTED LIKE JSON)');
    return {
      "software_engineer": {
        "id": "software_engineer",
        "title": "Software Engineer",
        "category": "Technology",
        "description":
            "Design, develop, and maintain software applications and systems",
        "icon": "💻",
        "salary_info": {
          "currency": "INR",
          "entry_level": {
            "min": 300000,
            "max": 800000,
            "average": 550000,
            "per": "annum"
          },
          "mid_level": {
            "min": 800000,
            "max": 2000000,
            "average": 1400000,
            "per": "annum"
          },
          "senior_level": {
            "min": 2000000,
            "max": 5000000,
            "average": 3500000,
            "per": "annum"
          }
        },
        "required_skills": {
          "technical_skills": [
            {
              "skill": "Programming Languages",
              "details": ["Java", "Python", "JavaScript"],
              "importance": "Critical",
              "learning_time": "6-12 months"
            },
            {
              "skill": "Data Structures & Algorithms",
              "details": ["Arrays", "LinkedList", "Trees"],
              "importance": "Critical",
              "learning_time": "4-8 months"
            }
          ],
          "soft_skills": [
            {"skill": "Problem Solving", "importance": "Critical"},
            {"skill": "Communication", "importance": "High"}
          ]
        },
        "academic_roadmap": {
          "higher_education": {
            "options": [
              {
                "degree": "Bachelor's Degree in Computer Science",
                "details": "A solid foundation in computer science principles",
                "duration": "4 years"
              }
            ]
          }
        }
      },
      "doctor": {
        "id": "doctor",
        "title": "Medical Doctor",
        "category": "Healthcare",
        "description":
            "Diagnose and treat illnesses, injuries, and other health conditions",
        "icon": "🩺",
        "salary_info": {
          "currency": "INR",
          "entry_level": {
            "min": 500000,
            "max": 1000000,
            "average": 750000,
            "per": "annum"
          },
          "mid_level": {
            "min": 1000000,
            "max": 3000000,
            "average": 2000000,
            "per": "annum"
          },
          "senior_level": {
            "min": 3000000,
            "max": 8000000,
            "average": 5000000,
            "per": "annum"
          }
        },
        "required_skills": {
          "technical_skills": [
            {
              "skill": "Clinical Knowledge",
              "importance": "Critical",
              "learning_time": "5+ years"
            },
            {
              "skill": "Diagnosis",
              "importance": "Critical",
              "learning_time": "Continuous"
            }
          ],
          "soft_skills": [
            {"skill": "Empathy", "importance": "Critical"},
            {"skill": "Communication", "importance": "Critical"}
          ]
        },
        "academic_roadmap": {
          "higher_education": {
            "options": [
              {
                "degree": "MBBS (Bachelor of Medicine)",
                "details": "Foundational medical degree",
                "duration": "5.5 years"
              }
            ]
          }
        }
      },
      "singer": {
        "id": "singer",
        "title": "Professional Singer",
        "category": "Arts & Entertainment",
        "description":
            "Perform vocal music for audiences across various platforms and genres",
        "icon": "🎤",
        "salary_info": {
          "currency": "INR",
          "entry_level": {
            "min": 100000,
            "max": 500000,
            "average": 300000,
            "per": "annum"
          },
          "mid_level": {
            "min": 500000,
            "max": 1500000,
            "average": 1000000,
            "per": "annum"
          },
          "senior_level": {
            "min": 1500000,
            "max": 5000000,
            "average": 3000000,
            "per": "annum"
          }
        },
        "required_skills": {
          "technical_skills": [
            {
              "skill": "Vocal Technique",
              "importance": "Critical",
              "learning_time": "Several years"
            },
            {
              "skill": "Music Theory",
              "importance": "High",
              "learning_time": "1-3 years"
            }
          ],
          "soft_skills": [
            {"skill": "Stage Presence", "importance": "High"},
            {"skill": "Networking", "importance": "High"}
          ]
        },
        "academic_roadmap": {
          "higher_education": {
            "options": [
              {
                "degree": "Music Degree",
                "details": "Formal music education (optional)",
                "duration": "3-4 years"
              }
            ]
          }
        }
      },
      "engineer": {
        "id": "engineer",
        "title": "Civil Engineer",
        "category": "Engineering",
        "description":
            "Design, build, and maintain infrastructure including buildings, roads, bridges, and water systems",
        "icon": "🏗️",
        "salary_info": {
          "currency": "INR",
          "entry_level": {
            "min": 300000,
            "max": 600000,
            "average": 450000,
            "per": "annum"
          },
          "mid_level": {
            "min": 600000,
            "max": 1200000,
            "average": 900000,
            "per": "annum"
          },
          "senior_level": {
            "min": 1200000,
            "max": 2500000,
            "average": 1800000,
            "per": "annum"
          }
        },
        "required_skills": {
          "technical_skills": [
            {
              "skill": "Structural Analysis",
              "importance": "Critical",
              "learning_time": "2-4 years"
            },
            {
              "skill": "CAD Software",
              "importance": "High",
              "learning_time": "6-12 months"
            }
          ],
          "soft_skills": [
            {"skill": "Problem Solving", "importance": "High"},
            {"skill": "Project Management", "importance": "High"}
          ]
        },
        "academic_roadmap": {
          "higher_education": {
            "options": [
              {
                "degree": "B.Tech/B.E. in Civil Engineering",
                "details": "Undergraduate degree in civil engineering",
                "duration": "4 years"
              }
            ]
          }
        }
      }
    };
  }

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
      final description = career['description']?.toString().toLowerCase() ?? '';
      final category = career['category']?.toString().toLowerCase() ?? '';

      if (title.contains(lowercaseQuery) ||
          description.contains(lowercaseQuery) ||
          category.contains(lowercaseQuery)) {
        filteredCareers[key] = career;
      }
    });

    return filteredCareers;
  }
}
