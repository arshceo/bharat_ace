import 'package:flutter_riverpod/flutter_riverpod.dart';
// For firstWhereOrNull if needed later

// --- Placeholder Models ---

// Represents the main task for the day
class DailyQuest {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final double progress; // 0.0 to 1.0
  final String subjectIcon; // e.g., 'science', 'math', 'history' (for icons)

  DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    this.progress = 0.0,
    required this.subjectIcon,
  });
}

// Represents rank and top student snippet
class LeaderboardSnippet {
  final int? yourRank;
  final int totalStudents;
  final String? topStudentName; // Name of #1

  LeaderboardSnippet(
      {this.yourRank, required this.totalStudents, this.topStudentName});
}

// Represents overall class progress
class ClassProgress {
  final double syllabusCompletionPercent; // 0.0 to 1.0

  ClassProgress({required this.syllabusCompletionPercent});
}

// Represents an upcoming event
enum EventType { test, assignment, announcement }

class EventItem {
  final String id;
  final String title;
  final DateTime dueDate;
  final EventType type;
  final String? subject; // Optional subject associated

  EventItem({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.type,
    this.subject,
  });
}

// --- Placeholder Providers ---

// Provider for Today's Main Quest
final dailyQuestProvider = FutureProvider<DailyQuest?>((ref) async {
  await Future.delayed(const Duration(milliseconds: 1200)); // Simulate fetch
  // Return null sometimes to test that state
  // if (DateTime.now().second % 3 == 0) return null;
  // if (DateTime.now().second % 5 == 0) throw Exception("Failed to load quest!"); // Simulate error

  return DailyQuest(
    id: 'q${DateTime.now().second}', // Make ID slightly dynamic for refresh demo
    title: 'Master Photosynthesis',
    description: 'Complete the interactive lesson and achieve 80% on the MCQs.',
    xpReward: 150,
    progress: 0.35, // 35% done
    subjectIcon: 'science', // You'll map this to an IconData
  );
});

// Provider for Leaderboard Snippet
final leaderboardSnippetProvider =
    FutureProvider<LeaderboardSnippet>((ref) async {
  await Future.delayed(const Duration(milliseconds: 1500));
  // if (DateTime.now().second % 7 == 0) throw Exception("Leaderboard Error!"); // Simulate error
  return LeaderboardSnippet(
      yourRank: 12, totalStudents: 45, topStudentName: 'Priya S.');
});

// Provider for Class Syllabus Progress
final classProgressProvider = FutureProvider<ClassProgress>((ref) async {
  await Future.delayed(const Duration(milliseconds: 900));
  // if (DateTime.now().second % 6 == 0) throw Exception("Class Progress Error!"); // Simulate error
  return ClassProgress(syllabusCompletionPercent: 0.68); // 68%
});

// Provider for Upcoming Events
final upcomingEventsProvider = FutureProvider<List<EventItem>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 1100));
  // if (DateTime.now().second % 8 == 0) return []; // Simulate no events
  // if (DateTime.now().second % 9 == 0) throw Exception("Events Error!"); // Simulate error

  final now = DateTime.now();
  return [
    EventItem(
        id: 'e1',
        title: 'Physics MST 1: Mechanics',
        dueDate: now.add(const Duration(days: 2, hours: 4)),
        type: EventType.test,
        subject: 'Physics'),
    EventItem(
        id: 'e2',
        title: 'History Essay: Mughal Era',
        dueDate: now.add(const Duration(days: 4)),
        type: EventType.assignment,
        subject: 'History'),
    EventItem(
        id: 'e3',
        title: 'Guest Lecture: AI Ethics',
        dueDate: now.add(const Duration(days: 1)),
        type: EventType.announcement),
    EventItem(
        id: 'e4',
        title: 'Math Quiz Chapter 3',
        dueDate: now.add(const Duration(hours: 5)),
        type: EventType.test,
        subject: 'Math'),
    EventItem(
        id: 'e5',
        title: 'Submit Chemistry Lab Report',
        dueDate: now.subtract(const Duration(hours: 2)),
        type: EventType.assignment,
        subject: 'Chemistry'), // Past due example
  ];
});

// Provider for Active Students Count (Using Stream for dynamic updates)
final activeStudentsProvider = StreamProvider<int>((ref) async* {
  // Simulate fluctuating active user count
  int count = 18;
  yield count; // Initial value
  await Future.delayed(
      const Duration(seconds: 5)); // Short delay before starting stream

  while (true) {
    await Future.delayed(
        const Duration(seconds: 10)); // Update every 10 seconds
    count += (DateTime.now().second % 7) - 3; // Random small change (-3 to +3)
    if (count < 8) count = 8; // Minimum 8 active
    if (count > 42) count = 42; // Maximum 42 active
    yield count; // Emit the new count
  }
});

// Provider for Bottom Navigation Index (Standard UI State)
final bottomNavIndexProvider = StateProvider<int>((ref) => 0); // 0 is Home
