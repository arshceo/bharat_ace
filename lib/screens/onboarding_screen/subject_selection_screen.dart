import 'package:bharat_ace/common/routes.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubjectSelectionScreen extends ConsumerStatefulWidget {
  const SubjectSelectionScreen({
    super.key,
  });

  @override
  _SubjectSelectionScreenState createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState
    extends ConsumerState<SubjectSelectionScreen> {
  List<String> _subjects = [];
  final List<String> _selectedSubjects = [];

  // Mock subject data (This should be fetched dynamically based on board & class)
  final Map<String, Map<String, List<String>>> _subjectData = {
    "CBSE": {
      "6": ["Math", "Science", "English", "Social Science", "Hindi"],
      "7": ["Math", "Physics", "Chemistry", "Biology", "Computer Science"],
      "8": ["Math", "Science", "English", "Social Science", "Hindi"],
      "9": ["Math", "Physics", "Chemistry", "Biology", "Computer Science"],
      "10": ["Math", "Science", "English", "Social Science", "Hindi"],
      "11": ["Math", "Physics", "Chemistry", "Biology", "Computer Science"],
      "12": ["Math", "Physics", "Chemistry", "Biology", "Computer Science"]
    },
    "PSEB": {
      "6": ["Math", "Science", "English", "Social Science", "Hindi"],
      "7": ["Math", "Physics", "Chemistry", "Biology", "Computer Science"],
      "8": ["Math", "Science", "English", "Social Science", "Hindi"],
      "9": ["Math", "Physics", "Chemistry", "Biology", "Computer Science"],
      "10": ["Math", "Science", "English", "Social Science", "Hindi"],
      "11": ["Math", "Physics", "Chemistry", "Biology", "Computer Science"],
      "12": ["Math", "Physics", "Chemistry", "Biology", "Computer Science"]
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() {
    setState(() {
      _subjects = _subjectData["CBSE"]?["10"] ?? [];
    });
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  void _continue() async {
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one subject!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final studentProvider = ref.read(studentDetailsProvider.notifier);
      final student = ref.read(studentDetailsProvider);

      if (student == null) {
        throw "Student data is missing!";
      }

      // Convert student model to JSON
      Map<String, dynamic> studentData = student.toJson();
      studentData["enrolledSubjects"] = _selectedSubjects; // Add subjects

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection("students")
          .doc(FirebaseAuth
              .instance.currentUser!.uid) // Use student ID as the document ID
          .set(studentData);

      // Navigate to the home screen
      Navigator.pushNamed(context, AppRoutes.main_layout_nav);
    } catch (error) {
      print("❌ Error saving student details: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving details. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = ref.read(studentDetailsProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            Text("Select Your Subjects", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(studentProvider!.grade),
            // XP Progress Bar (Mocked value for now)
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 300,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  AnimatedContainer(
                    duration: Duration(seconds: 1),
                    width: 250, // Adjust dynamically
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Subjects Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  String subject = _subjects[index];
                  bool isSelected = _selectedSubjects.contains(subject);

                  return GestureDetector(
                    onTap: () => _toggleSubject(subject),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blueAccent : Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          subject,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            // Continue Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                shadowColor: Colors.blueAccent,
                elevation: 10,
              ),
              onPressed: _continue,
              child: const Text(
                "Continue →",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
