// --- subject_selection_screen.dart (Complete Code) ---
import 'package:bharat_ace/common/routes.dart';
import 'package:bharat_ace/core/models/student_model.dart'; // Import StudentModel
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubjectSelectionScreen extends ConsumerStatefulWidget {
  const SubjectSelectionScreen({super.key});

  @override
  ConsumerState<SubjectSelectionScreen> createState() =>
      _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState
    extends ConsumerState<SubjectSelectionScreen> {
  List<String> _availableSubjects = []; // Subjects available for selection
  final List<String> _selectedSubjects = []; // Subjects user has chosen
  bool _isLoading = false; // For loading state during save
  bool _isLoadingSubjects = true; // **NEW**: For loading subjects initially

  // Subject data - Keep mock data as fallback or remove if always fetched
  final Map<String, Map<String, List<String>>> _subjectData = {
    /* ... your mock data ... */
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
    // Add other boards/classes
  };

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to access ref safely in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubjectsBasedOnProfile();
    });
  }

  // **MODIFIED**: Load subjects based on student profile in provider
  void _loadSubjectsBasedOnProfile() {
    setState(() => _isLoadingSubjects = true); // Start loading
    final StudentModel? student =
        ref.read(studentDetailsProvider); // Read data once

    if (student != null &&
        student.board.isNotEmpty &&
        student.grade.isNotEmpty) {
      // Try to get subjects from mock data based on board and grade
      final boardSubjects = _subjectData[student.board];
      final classSubjects = boardSubjects?[student.grade];

      setState(() {
        _availableSubjects =
            classSubjects ?? []; // Use fetched list or empty list
        _isLoadingSubjects = false; // Finish loading
        print(
            "Loaded subjects for ${student.board} / ${student.grade}: $_availableSubjects");
      });
      if (classSubjects == null) {
        print(
            "Warning: No subject data found for Board: ${student.board}, Grade: ${student.grade}. Using empty list.");
      }
    } else {
      // Handle case where student data isn't fully available (shouldn't happen if onboarding flow is correct)
      setState(() {
        _availableSubjects = []; // Default to empty list on error/missing data
        _isLoadingSubjects = false; // Finish loading
      });
      print(
          "Error: Could not load subjects because student board or grade is missing.");
      // Optionally show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Error: Student profile incomplete."),
            backgroundColor: Colors.red),
      );
    }
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

  // **MODIFIED**: _continue method (Logic was already correct)
  void _continue() async {
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select at least one subject!"),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Set loading state
    setState(() => _isLoading = true);

    final studentNotifier = ref.read(studentDetailsProvider.notifier);

    try {
      // 1. Update the state in the notifier with selected subjects
      studentNotifier.updateEnrolledSubjects(_selectedSubjects);

      // 2. Trigger the Firestore save using the method in the notifier
      await studentNotifier.saveStudentDataToFirestore();

      // 3. Navigate to home on successful save
      if (mounted) {
        // Navigate to main layout and remove all previous routes
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.main_layout_nav, (route) => false);
      }
    } catch (error) {
      print("❌ Error saving final student details: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error saving profile: ${error.toString()}"),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider to rebuild if needed (though read is often sufficient in callbacks)
    final student = ref.watch(studentDetailsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        /* ... AppBar code ... */
        title: const Text("Select Your Subjects",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black, elevation: 0,
        automaticallyImplyLeading:
            false, // Prevent back button if this is final step
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Display student's grade for confirmation
            if (student != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text("For Class: ${student.grade} (${student.board})",
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 16)),
              ),

            // Removed Mock XP Bar - Show loading indicator for subjects instead
            if (_isLoadingSubjects)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_availableSubjects.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                    child: Text("No subjects found for your class/board.",
                        style: TextStyle(color: Colors.redAccent))),
              )
            else
              // Subjects Grid
              Expanded(
                child: GridView.builder(
                  /* ... GridView code ... */
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10),
                  itemCount: _availableSubjects.length,
                  itemBuilder: (context, index) {
                    String subject = _availableSubjects[index];
                    bool isSelected = _selectedSubjects.contains(subject);
                    return GestureDetector(
                        onTap: () => _toggleSubject(subject),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: Colors.blueAccent
                                                .withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2)
                                      ]
                                    : []),
                            child: Center(
                                child: Text(subject,
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)))));
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Continue Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shadowColor: Colors.blueAccent,
                  elevation: 10),
              // Disable button while saving or if subjects haven't loaded
              onPressed:
                  _isLoading || _isLoadingSubjects || _availableSubjects.isEmpty
                      ? null
                      : _continue,
              child: _isLoading // Show loading indicator on button
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3))
                  : const Text("Finish Setup →",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
