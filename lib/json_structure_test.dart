import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSON Structure Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const JsonStructureTest(),
    );
  }
}

class JsonStructureTest extends StatefulWidget {
  const JsonStructureTest({Key? key}) : super(key: key);

  @override
  State<JsonStructureTest> createState() => _JsonStructureTestState();
}

class _JsonStructureTestState extends State<JsonStructureTest> {
  bool _isLoading = true;
  String _jsonDataText = '';
  String _careerFields = '';
  String _skillsStructure = '';
  String _academicStructure = '';

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Attempt to load the JSON file
      final String jsonString =
          await rootBundle.loadString('assets/career_database.json');

      // Parse the JSON
      final jsonData = json.decode(jsonString);

      if (jsonData.containsKey('careers_database')) {
        final careers = jsonData['careers_database'] as Map<String, dynamic>;

        if (careers.isNotEmpty) {
          // Get the first career entry to analyze structure
          final String firstCareerKey = careers.keys.first;
          final careerData = careers[firstCareerKey];

          // Get top level fields
          final List<String> topLevelFields = careerData.keys.toList();

          // Get skills structure if available
          String skillsStructure = 'No skills data found';
          if (careerData['required_skills'] != null) {
            final reqSkills = careerData['required_skills'];
            skillsStructure =
                'required_skills structure:\n${json.encode(reqSkills)}';
          } else if (careerData['roadmap'] != null &&
              careerData['roadmap']['skills'] != null) {
            final roadmapSkills = careerData['roadmap']['skills'];
            skillsStructure =
                'roadmap.skills structure:\n${json.encode(roadmapSkills)}';
          }

          // Get academic structure
          String academicStructure = 'No academic data found';
          if (careerData['academic_roadmap'] != null) {
            final academic = careerData['academic_roadmap'];
            academicStructure =
                'academic_roadmap structure:\n${json.encode(academic)}';
          } else if (careerData['roadmap'] != null &&
              careerData['roadmap']['education'] != null) {
            final education = careerData['roadmap']['education'];
            academicStructure =
                'roadmap.education structure:\n${json.encode(education)}';
          }

          setState(() {
            _jsonDataText =
                'JSON loaded successfully - ${careers.length} careers found';
            _careerFields = 'Career Fields: ${topLevelFields.join(", ")}';
            _skillsStructure = skillsStructure;
            _academicStructure = academicStructure;
            _isLoading = false;
          });
        } else {
          setState(() {
            _jsonDataText = 'No careers found in the JSON data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _jsonDataText =
              'Invalid JSON structure - no careers_database key found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _jsonDataText = 'Error loading JSON: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Structure Test'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _jsonDataText,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _careerFields,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Skills Structure:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _skillsStructure,
                      style: const TextStyle(
                          fontSize: 14, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Academic Structure:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _academicStructure,
                      style: const TextStyle(
                          fontSize: 14, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _loadJsonData,
                    child: const Text('Reload JSON Data'),
                  ),
                ],
              ),
            ),
    );
  }
}
