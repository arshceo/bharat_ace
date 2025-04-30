// lib/screens/smaterial/chapter_landing_screen.dart (Production Ready)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/models/progress_models.dart';
import 'package:bharat_ace/core/providers/progress_provider.dart';
import 'package:bharat_ace/core/providers/syllabus_provider.dart';
import 'prerequisite_check_screen.dart';
import 'level_content_screen.dart';

class ChapterLandingScreen extends ConsumerWidget {
  final String subjectName;
  final String chapterId;

  const ChapterLandingScreen(
      {super.key, required this.subjectName, required this.chapterId});

  // Helper moved inside build or separate utility class
  ChapterDetailed? _findChapterData(
      Syllabus? syllabus, String subjectKeyOrSubKey, String chapterId) {
    if (syllabus == null) {
      print("_findChapterData: Syllabus data is null.");
      return null;
    }
    print(
        "    _findChapterData: Searching for Subject/SubKey='$subjectKeyOrSubKey', ChapterID='$chapterId'");

    ChapterDetailed? foundChapter;

    // Function to search within a list of chapters
    ChapterDetailed? searchChapters(
        List<ChapterDetailed> chapters, String idToFind) {
      final chapter = chapters.firstWhere((ch) => ch.chapterId == idToFind,
          orElse: () => ChapterDetailed.empty() // Use the empty factory
          );
      return chapter.chapterId.isNotEmpty ? chapter : null;
    }

    // Check if subjectKeyOrSubKey exists as a main subject key
    if (syllabus.subjects.containsKey(subjectKeyOrSubKey)) {
      final subjectData = syllabus.subjects[subjectKeyOrSubKey]!;
      // Check direct chapters of this main subject
      foundChapter = searchChapters(subjectData.chapters, chapterId);
      if (foundChapter != null) {
        print(
            "    _findChapterData: Found chapter in main subject '$subjectKeyOrSubKey'");
        return foundChapter;
      }
      // If not found directly, check if this main subject has sub-subjects
      if (subjectData.subSubjects != null) {
        subjectData.subSubjects!.forEach((subKey, subData) {
          if (foundChapter == null) {
            // Search only if not already found
            foundChapter = searchChapters(subData.chapters, chapterId);
            if (foundChapter != null) {
              print(
                  "    _findChapterData: Found chapter in sub-subject '$subKey' under main subject '$subjectKeyOrSubKey'");
            }
          }
        });
        if (foundChapter != null) return foundChapter;
      }
    }

    // If not found by direct key match, iterate through all subjects and their potential sub-subjects
    // This handles cases where subjectName passed might be a sub-subject key directly
    if (foundChapter == null) {
      print(
          "    _findChapterData: Subject key '$subjectKeyOrSubKey' not a direct match or chapter not found within it. Searching all subjects/sub-subjects...");
      syllabus.subjects.forEach((mainSubjectKey, subjectData) {
        if (foundChapter != null) return;

        // Check direct chapters again (should be redundant if subjectKey was correct main key, but safe)
        foundChapter = searchChapters(subjectData.chapters, chapterId);
        if (foundChapter != null) {
          print(
              "    _findChapterData: Found chapter in main subject '$mainSubjectKey' during broad search.");
          return;
        }

        // Check sub-subjects
        if (subjectData.subSubjects != null) {
          subjectData.subSubjects!.forEach((subSubjectKey, subSubjectData) {
            if (foundChapter == null) {
              // Check if the passed name matches this sub-key OR just search chapters
              if (subSubjectKey == subjectKeyOrSubKey) {
                foundChapter =
                    searchChapters(subSubjectData.chapters, chapterId);
                if (foundChapter != null) {
                  print(
                      "    _findChapterData: Found chapter in specific sub-subject '$subSubjectKey'.");
                }
              } else {
                // Fallback: check chapters even if sub-key doesn't match initially passed key
                final potentialChapter = subSubjectData.chapters.firstWhere(
                    (ch) => ch.chapterId == chapterId,
                    orElse: () => ChapterDetailed.empty());
                if (potentialChapter.chapterId.isNotEmpty) {
                  print(
                      "    _findChapterData: Found chapter in sub-subject '$subSubjectKey' during broad search.");
                  foundChapter = potentialChapter;
                }
              }
            }
          });
          if (foundChapter != null) return;
        }
      });
    }

    if (foundChapter == null) {
      print(
          "    _findChapterData: Chapter ID '$chapterId' could NOT BE LOCATED anywhere in the syllabus structure.");
    }
    return foundChapter;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both syllabus and progress for the specific chapter
    final AsyncValue<Syllabus> syllabusAsync = ref.watch(syllabusProvider);
    // Pass both subject and chapterId correctly to the family provider
    final AsyncValue<ChapterProgress> chapterProgressAsync = ref.watch(
        chapterProgressProvider(
            (subject: subjectName, chapterId: chapterId)) // Pass tuple
        );

    // Show loading/error based on BOTH providers
    if (syllabusAsync is AsyncLoading || chapterProgressAsync is AsyncLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text("Loading Chapter...")),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (syllabusAsync is AsyncError || chapterProgressAsync is AsyncError) {
      final syllabusError = syllabusAsync.error?.toString() ?? '';
      final progressError = chapterProgressAsync.error?.toString() ?? '';
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: Center(
              child: Text(
                  "Error loading data:\nSyllabus: $syllabusError\nProgress: $progressError")));
    }

    // If both loaded successfully
    final Syllabus syllabus =
        syllabusAsync.value!; // We know it's not null/error here
    final ChapterProgress progress =
        chapterProgressAsync.value!; // We know it's not null/error here

    final ChapterDetailed? chapterData =
        _findChapterData(syllabus, subjectName, chapterId);

    if (chapterData == null) {
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body:
              Center(child: Text("Chapter data not found for ID: $chapterId")));
    }

    // --- Navigation Logic ---
    // Use WidgetsBinding to schedule navigation after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return; // Check validity

      if (!progress.prereqsChecked && chapterData.prerequisites.isNotEmpty) {
        // Only go if there ARE prereqs
        print(
            "Navigating to Prerequisite Check for ${chapterData.chapterTitle}");
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => PrerequisiteCheckScreen(
                    subject: subjectName,
                    chapterId: chapterId,
                    chapterData: chapterData)));
      } else if (progress.currentLevel != "Mastered") {
        // Go to content if not mastered
        print(
            "Navigating to Level Content for ${chapterData.chapterTitle} - Level: ${progress.currentLevel}");
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => LevelContentScreen(
                    subject: subjectName,
                    chapterId: chapterId,
                    levelName: progress.currentLevel,
                    chapterData: chapterData)));
      } else {
        // Chapter Mastered! Navigate to a summary/completion screen or back
        print("Chapter ${chapterData.chapterTitle} already mastered!");
        Navigator.pop(context); // Example: Just go back
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("${chapterData.chapterTitle} already mastered!")));
      }
    });

    // Display a loading indicator while the navigation logic runs
    return Scaffold(
      appBar: AppBar(title: Text(chapterData.chapterTitle)),
      body: Center(child: Text("Loading ${progress.currentLevel}...")),
    );
  }
}
