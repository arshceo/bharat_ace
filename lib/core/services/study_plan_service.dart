// lib/core/services/study_plan_service.dart
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/models/study_task_model.dart';

class StudyPlanService {
  // *** MODIFIED: Return a List of Tasks ***
  Future<List<StudyTask>> getTodaysTasks(StudentModel student) async {
    // Renamed and changed return type
    // Simulate network delay or complex calculation
    await Future.delayed(const Duration(milliseconds: 700));

    List<StudyTask> tasks = [];

    // --- MVP Rule-Based Logic ---
    // Generate multiple tasks based on rules

    // Task 1 Example (Science)
    if (student.grade == "10" &&
        student.board == "CBSE" &&
        student.enrolledSubjects.contains("Science")) {
      tasks.add(StudyTask(
        id: "task_sci10_ch1_react", // Unique ID
        title: "Revisit Chemical Reactions",
        description:
            "Review notes on types of reactions and balancing equations.",
        subject: "Science",
        chapter: "Chapter 1: Chemical Reactions",
        topic: "Balancing Equations",
        estimatedTimeMinutes: 15,
        xpReward: 75,
      ));
    }

    // Task 2 Example (Math)
    if (student.enrolledSubjects.contains("Math")) {
      tasks.add(StudyTask(
        id: "task_math${student.grade}_practice",
        title: "Practice ${student.grade}th Math Problems",
        description: "Solve 5 problems from the current Math chapter exercise.",
        subject: "Math",
        chapter: "Current Math Chapter", // Make dynamic later
        topic: "Practice Problems",
        estimatedTimeMinutes: 20,
        xpReward: 50,
      ));
    }

    // Task 3 Example (Generic Revision)
    if (student.enrolledSubjects.contains("English")) {
      tasks.add(StudyTask(
        id: "task_eng${student.grade}_vocab",
        title: "Learn English Vocabulary",
        description:
            "Use flashcards to learn 5 new English words and their meanings.",
        subject: "English",
        estimatedTimeMinutes: 10,
        xpReward: 30,
      ));
    }

    // Add more rules/tasks...

    // If no specific tasks generated, maybe add a default one
    if (tasks.isEmpty && student.enrolledSubjects.isNotEmpty) {
      tasks.add(StudyTask(
        id: "task_generic_revise",
        title: "Quick Revision",
        description:
            "Spend 15 minutes revising any challenging topic from your subjects.",
        subject: student.enrolledSubjects.first, // Pick first subject
        estimatedTimeMinutes: 15,
        xpReward: 25,
      ));
    }

    return tasks; // Return the list
  }
  // ... other service methods ...
}
