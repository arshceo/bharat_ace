// lib/screens/smaterial/prerequisite_check_screen.dart (Production Ready)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/core/providers/progress_provider.dart';
// To update progress

// State for quiz loading
final _isCheckingPrereqsProvider =
    StateProvider.autoDispose<bool>((ref) => false);

class PrerequisiteCheckScreen extends ConsumerWidget {
  final String subject;
  final String chapterId;
  final ChapterDetailed chapterData;

  const PrerequisiteCheckScreen(
      {super.key,
      required this.subject,
      required this.chapterId,
      required this.chapterData});

  Future<void> _runPrerequisiteQuiz(BuildContext context, WidgetRef ref) async {
    if (ref.read(_isCheckingPrereqsProvider)) return; // Prevent double taps

    ref.read(_isCheckingPrereqsProvider.notifier).state = true;

    print("Running Prerequisite Quiz for ${chapterData.chapterTitle}");
    // TODO: Implement ACTUAL Quiz Logic
    // 1. Get prerequisite concept IDs/names from chapterData.prerequisites
    // 2. Generate relevant questions (AI Content Service or Question Bank)
    // 3. Show real Quiz UI (maybe push a new screen/modal)
    // 4. Evaluate results
    bool passed = await showDialog<bool>(
            context: context,
            barrierDismissible: false, // User must answer
            builder: (ctx) => AlertDialog(
                  title: const Text("Prerequisite Check"),
                  content: Text(
                      "Simulating prerequisite check for concepts like:\n${chapterData.prerequisites.map((p) => p.conceptName).join(', ')}.\n\nDid you pass?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("No")),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Yes")),
                  ],
                )) ??
        false;

    if (passed) {
      print("Prereqs Passed! Updating status...");
      final studentId = ref.read(studentDetailsProvider)?.id;
      if (studentId != null && studentId.isNotEmpty) {
        try {
          // Update progress in Firestore via Service
          await ref.read(progressServiceProvider).updateChapterLevelAndPrereqs(
              studentId,
              subject, // Pass subject
              chapterId,
              "Fundamentals", // Set starting level after passing prereqs
              true // Mark prereqs as checked
              );
          ref.invalidate(chapterProgressProvider((
            subject: subject,
            chapterId: chapterId
          ))); // Invalidate to reload
          if (context.mounted) {
            Navigator.pop(context); // Go back to Landing which will redirect
          }
        } catch (e) {
          print("Error updating progress after prereq check: $e");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Error saving progress: $e"),
                backgroundColor: Colors.red));
          }
        }
      } else {
        print("Error: Student ID not found for progress update.");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Error: Could not identify student."),
              backgroundColor: Colors.red));
        }
      }
    } else {
      print("Prereqs Failed!");
      // TODO: Provide better guidance - links to prerequisite topics/chapters
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Please review the prerequisite topics first. Guidance coming soon.")));
      }
    }

    if (context.mounted) {
      ref.read(_isCheckingPrereqsProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prerequisites = chapterData.prerequisites;
    final bool isChecking = ref.watch(_isCheckingPrereqsProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
          title: Text("Prerequisite Check: ${chapterData.chapterTitle}",
              style: textTheme.titleMedium),
          elevation: 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Before starting '${chapterData.chapterTitle}', let's review the basics!",
                style: textTheme.titleLarge),
            const SizedBox(height: 15),
            Text("Key prerequisite concepts:", style: textTheme.titleMedium),
            const SizedBox(height: 10),
            if (prerequisites.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                      "No specific prerequisites listed. Ready to start the check!",
                      style: TextStyle(fontStyle: FontStyle.italic)))
            else
              Expanded(
                child: ListView.builder(
                    itemCount: prerequisites.length,
                    itemBuilder: (ctx, index) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text("${index + 1}")),
                          title: Text(prerequisites[index].conceptName),
                          subtitle: Text(
                              "Importance: ${prerequisites[index].importance}"),
                          // TODO: Add onTap to navigate to prerequisite content if needed
                        ))),
              ),
            const Spacer(),
            Center(
                child: ElevatedButton.icon(
              icon: isChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.school_outlined),
              label:
                  Text(isChecking ? "Checking..." : "Start Prerequisite Check"),
              onPressed: isChecking
                  ? null
                  : () => _runPrerequisiteQuiz(
                      context, ref), // Disable while checking
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
