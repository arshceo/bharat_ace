// --- lib/screens/syllabus/syllabus_screen.dart (Corrected - Final Version for Current Flow) ---

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Keep if using .ms etc.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart'; // Keep for FadeInUp/FadeIn

// --- Import Models and Providers (Ensure paths are correct) ---
import 'package:bharat_ace/core/models/syllabus_models.dart'; // Import detailed models
import 'package:bharat_ace/core/providers/syllabus_provider.dart'; // Import CORRECT syllabus provider
import 'package:bharat_ace/core/providers/student_details_provider.dart'; // To display class/board
import 'package:bharat_ace/core/providers/progress_provider.dart'; // Import progress provider (used in chapter tile)
import 'package:bharat_ace/core/models/progress_models.dart'; // Import progress model
import 'package:bharat_ace/core/models/student_model.dart'; // Import StudentModel

// --- Import Navigation Target ---
import 'package:bharat_ace/screens/smaterial/chapter_landing_screen.dart'; // Target screen is ChapterLandingScreen

class SyllabusScreen extends ConsumerWidget {
  const SyllabusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final AsyncValue<Syllabus> syllabusAsync = ref.watch(syllabusProvider);
    final StudentModel? student = ref.watch(studentDetailsProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(student != null
            ? "Syllabus - Class ${student.grade} (${student.board})"
            : "Syllabus"),
        elevation: 1,
      ),
      body: syllabusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          print("Syllabus Screen Error: $error\n$stackTrace");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 45),
                const SizedBox(height: 16),
                Text("Could not load syllabus.",
                    style: textTheme.titleMedium
                        ?.copyWith(color: colorScheme.error),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                    "Please check your connection or ensure your profile (Grade/Board) is set correctly.\nError: ${error.toString()}",
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    onPressed: () => ref.invalidate(syllabusProvider))
              ]),
            ),
          );
        },
        data: (syllabus) {
          // syllabus is a Syllabus object
          final subjectsMap = syllabus.subjects;
          if (subjectsMap.isEmpty) {
            return const Center(
                child: Text("No syllabus data found for your class/board."));
          }
          final subjectNames = subjectsMap.keys.toList()..sort();

          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            itemCount: subjectNames.length,
            itemBuilder: (context, index) {
              final subjectName = subjectNames[index];
              final SubjectDetailed subjectData = subjectsMap[subjectName]!;

              return FadeInUp(
                delay: (index * 60).ms,
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                        backgroundColor:
                            colorScheme.primaryContainer.withOpacity(0.5),
                        child: Icon(_getSubjectIcon(subjectName),
                            color: colorScheme.primary, size: 24)),
                    title: Text(subjectName,
                        style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18)), // Pass subjectName for context
                    childrenPadding: const EdgeInsets.only(
                        left: 0, right: 16, bottom: 8), // Adjust padding
                    expandedCrossAxisAlignment: CrossAxisAlignment
                        .stretch, // Stretch children horizontally
                    trailing: ExpandIcon(
                      color: colorScheme.onSurfaceVariant,
                      expandedColor: colorScheme.primary,
                      onPressed: (bool value) {},
                    ),
                    // Pass SubjectDetailed to helper which returns List<Widget> (chapter tiles or sub-subject sections)
                    children: _buildExpansionTileChildren(
                        context, ref, subjectName, subjectData),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper to build children for ExpansionTile (handles chapters or sub-subjects)
  List<Widget> _buildExpansionTileChildren(BuildContext context, WidgetRef ref,
      String mainSubjectName, SubjectDetailed subjectData) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    const double subSubjectIndent = 15.0;
    const double chapterIndent =
        30.0; // Further indent chapters under sub-subjects

    // Case 1: Direct Chapters
    if (subjectData.chapters.isNotEmpty) {
      if (subjectData.chapters.isEmpty) {
        return [
          ListTile(
              dense: true,
              contentPadding: EdgeInsets.only(left: chapterIndent + 16.0),
              title: Text("No chapters listed.",
                  style: TextStyle(fontStyle: FontStyle.italic)))
        ];
      }
      // Pass the main subject's name
      return subjectData.chapters
          .map((chapter) =>
              _buildChapterTile(context, ref, mainSubjectName, chapter))
          .toList(); // Add indent
    }
    // Case 2: Sub Subjects
    else if (subjectData.subSubjects != null &&
        subjectData.subSubjects!.isNotEmpty) {
      List<Widget> subSubjectWidgets = [];
      subjectData.subSubjects!.forEach((subSubjectName, subSubjectData) {
        // Add Sub-Subject Title
        subSubjectWidgets.add(Padding(
            padding: EdgeInsets.only(
                top: 10.0, bottom: 4.0, left: subSubjectIndent + 16.0),
            child: Text(subSubjectName,
                style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500, color: colorScheme.primary))));
        // Add Chapters for this Sub-Subject
        if (subSubjectData.chapters.isEmpty) {
          subSubjectWidgets.add(ListTile(
              dense: true,
              contentPadding: EdgeInsets.only(left: chapterIndent + 16.0),
              title: Text("No chapters listed.",
                  style: TextStyle(fontStyle: FontStyle.italic))));
        } else {
          subSubjectWidgets.addAll(subSubjectData.chapters.map((chapter) =>
              _buildChapterTile(context, ref, subSubjectName, chapter)));
        } // Pass subSubjectName and indent
        subSubjectWidgets.add(const SizedBox(height: 5));
      });
      return subSubjectWidgets;
    }
    // Case 3: Empty
    else {
      return [
        ListTile(
            dense: true,
            contentPadding: EdgeInsets.only(left: chapterIndent + 16.0),
            title: Text("No syllabus content available.",
                style: TextStyle(fontStyle: FontStyle.italic)))
      ];
    }
  }

  // Helper to build ListTile for each chapter
  Widget _buildChapterTile(BuildContext context, WidgetRef ref,
      String subjectName, ChapterDetailed chapter) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final progressAsync = ref.watch(chapterProgressProvider(
        (subject: subjectName, chapterId: chapter.chapterId)));
    final String progressText = progressAsync.maybeWhen(
        data: (p) => p.currentLevel ?? 'Not Started',
        error: (e, s) => 'Error',
        orElse: () => '...');
    final bool isMastered =
        progressAsync.valueOrNull?.currentLevel == "Mastered";

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 30, right: 8),
      title: Text(chapter.chapterTitle, style: textTheme.bodyLarge),
      subtitle: Text("Status: $progressText",
          style: textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant)),
      leading: Icon(
          isMastered
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: isMastered
              ? Colors.green.shade600
              : colorScheme.primary.withOpacity(0.8)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () {
        print(
            "Tapped Chapter: ${chapter.chapterTitle} (ID: ${chapter.chapterId}), Subject: $subjectName");
        // *** Navigate to ChapterLandingScreen ***
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChapterLandingScreen(
                      subjectName:
                          subjectName, // Pass the correct subject name/key
                      chapterId:
                          chapter.chapterId, // Pass the unique chapter ID
                    )));
      },
    );
  }

  // Helper to get an icon based on subject name
  IconData _getSubjectIcon(String subjectName) {
    String lowerSub = subjectName.toLowerCase();
    if (lowerSub.contains("math")) return Icons.calculate_outlined;
    if (lowerSub.contains("science")) return Icons.science_outlined;
    if (lowerSub.contains("physics")) return Icons.thermostat_auto_outlined;
    if (lowerSub.contains("chemistry")) return Icons.biotech_outlined;
    if (lowerSub.contains("biology")) return Icons.bug_report_outlined;
    if (lowerSub.contains("english")) return Icons.translate;
    if (lowerSub.contains("hindi")) return Icons.translate;
    if (lowerSub.contains("social")) {
      return Icons.public_outlined; // Catch Social Science/Studies
    }
    if (lowerSub.contains("history")) return Icons.history_edu_outlined;
    if (lowerSub.contains("geography")) return Icons.map_outlined;
    if (lowerSub.contains("civics")) return Icons.gavel_outlined;
    if (lowerSub.contains("economic")) return Icons.show_chart_outlined;
    if (lowerSub.contains("computer")) return Icons.computer_outlined;
    return Icons.book_outlined; // Default
  }
}
// --- End of SyllabusScreen class ---
