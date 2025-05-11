// --- lib/screens/syllabus/syllabus_screen.dart (Revamped UI with Progress Placeholders) ---

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Import percent indicator

// --- Import Models and Providers --- (Ensure paths are correct)
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/providers/syllabus_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/core/providers/progress_provider.dart'; // Still needed for chapter tile status
import 'package:bharat_ace/core/models/student_model.dart';

// --- Import Navigation Target ---
import 'package:bharat_ace/screens/smaterial/chapter_landing_screen.dart';
import 'package:shimmer/shimmer.dart';

class SyllabusScreen extends ConsumerWidget {
  const SyllabusScreen({super.key});

  // --- Colors (Example Dark Theme - Move to AppTheme later) ---
  static const Color darkBg = Color(0xFF12121F);
  static const Color primaryPurple = Color(0xFF8A2BE2);
  static const Color accentCyan = Color(0xFF00FFFF);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color surfaceLight = Color(0xFF2A2A3A);
  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFFAAAAAA);
  // --- End Colors ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Syllabus> syllabusAsync = ref.watch(syllabusProvider);
    final StudentModel? student = ref.watch(studentDetailsProvider);
    final TextTheme textTheme = Theme.of(context).textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary); // Apply dark theme text colors
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme; // Or use manual colors

    return Scaffold(
      backgroundColor: darkBg, // Dark background
      appBar: AppBar(
        title: Text(
            student != null ? "Syllabus - Class ${student.grade}" : "Syllabus",
            style: TextStyle(color: textPrimary)),
        backgroundColor: surfaceDark, // Dark AppBar
        foregroundColor: textPrimary,
        elevation: 1,
        // Remove back button if this is a root tab screen
        // automaticallyImplyLeading: false,
      ),
      body: syllabusAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: accentCyan)),
        error: (error, stackTrace) {
          print("Syllabus Screen Error: $error\n$stackTrace");
          return Center(
            child: _buildErrorCard(
                // Call the existing helper
                context,
                "Could not load syllabus.",
                error, // Pass the error object
                () =>
                    ref.invalidate(syllabusProvider) // Pass the retry function
                ),
          );
        },
        data: (syllabus) {
          final subjectsMap = syllabus.subjects;
          if (subjectsMap.isEmpty) {
            return const Center(
                child: Text("No syllabus data found.",
                    style: TextStyle(color: textSecondary)));
          }
          final subjectNames = subjectsMap.keys.toList()..sort();

          // *** Use Column + ListView for Header + List ***
          return Column(
            children: [
              // --- Overall Progress Header ---
              _buildOverallProgressHeader(context, textTheme, 0.8,
                  "On Track"), // Placeholder values 65%, On Track
              const Divider(height: 1, color: surfaceLight), // Separator

              // --- Subject List ---
              Expanded(
                // Make the list scrollable
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
                  itemCount: subjectNames.length,
                  itemBuilder: (context, index) {
                    final subjectName = subjectNames[index];
                    final SubjectDetailed subjectData =
                        subjectsMap[subjectName]!;
                    // Placeholder progress per subject
                    final double subjectProgress =
                        (subjectName.hashCode % 50 + 50) /
                            100.0; // Random placeholder (50-99%)

                    return FadeInUp(
                      delay: (index * 60).ms,
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        color: surfaceLight, // Card background
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                              backgroundColor: primaryPurple.withOpacity(0.2),
                              child: Icon(_getSubjectIcon(subjectName),
                                  color: primaryPurple, size: 24)),
                          title: Text(subjectName,
                              style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: textPrimary)),
                          // Show placeholder progress in subtitle
                          subtitle: Text(
                            "Progress: ${(subjectProgress * 100).toInt()}%", // Placeholder
                            style: textTheme.bodySmall
                                ?.copyWith(color: textSecondary),
                          ),
                          childrenPadding: const EdgeInsets.only(
                              left: 0, right: 16, bottom: 8),
                          expandedCrossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          iconColor:
                              textSecondary, // Color for the default chevron icon
                          collapsedIconColor: textSecondary,
                          // Trailing icon is handled automatically by ExpansionTile
                          // trailing: ExpandIcon(...) // REMOVED
                          children: _buildExpansionTileChildren(
                              context, ref, subjectName, subjectData),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 75,
              ) // Bottom padding,
            ],
          );
        },
      ),
    );
  }

  // --- New Helper: Overall Progress Header ---
  Widget _buildOverallProgressHeader(BuildContext context, TextTheme textTheme,
      double overallProgress, String readinessStatus) {
    String readinessMessage;
    Color readinessColor;
    IconData readinessIcon;

    // Determine readiness message/color based on progress (EXAMPLE LOGIC)
    if (overallProgress >= 0.8) {
      readinessMessage = "Exam Ready!";
      readinessColor = Colors.greenAccent.shade400;
      readinessIcon = Icons.check_circle_rounded;
    } else if (overallProgress >= 0.5) {
      readinessMessage = "On Track";
      readinessColor = Colors.orangeAccent.shade200;
      readinessIcon = Icons.timelapse_rounded;
    } else {
      readinessMessage = "Needs Focus";
      readinessColor = Colors.redAccent.shade100;
      readinessIcon = Icons.warning_amber_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          // Progress Ring
          FadeInLeft(
            child: SizedBox(
              width: 80,
              height: 80,
              child: CircularPercentIndicator(
                radius: 40.0,
                lineWidth: 7.0,
                percent: overallProgress,
                center: Text("${(overallProgress * 100).toInt()}%",
                    style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: textPrimary)),
                progressColor: accentCyan,
                backgroundColor: surfaceLight,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 1000,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Text Info
          Expanded(
            child: FadeInRight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Overall Progress",
                      style:
                          textTheme.bodyMedium?.copyWith(color: textSecondary)),
                  Text("Keep up the great work!",
                      style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          height: 1.2)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(readinessIcon, color: readinessColor, size: 18),
                      const SizedBox(width: 6),
                      Text("Readiness: $readinessMessage",
                          style: textTheme.bodyMedium?.copyWith(
                              color: readinessColor,
                              fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build children for ExpansionTile (handles chapters or sub-subjects)
  List<Widget> _buildExpansionTileChildren(BuildContext context, WidgetRef ref,
      String mainSubjectName, SubjectDetailed subjectData) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    const double subSubjectIndent = 15.0;
    const double chapterIndent = 30.0;

    List<Widget> buildChapterTiles(
        String subjectCtx, List<ChapterDetailed> chapters) {
      if (chapters.isEmpty) {
        return [
          ListTile(
              dense: true,
              contentPadding: EdgeInsets.only(left: chapterIndent + 16.0),
              title: Text("No chapters listed.",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: textSecondary)))
        ];
      }
      return chapters
          .map((chapter) => _buildChapterTile(
              context, ref, subjectCtx, chapter, chapterIndent))
          .toList();
    }

    // Case 1: Direct Chapters
    if (subjectData.chapters.isNotEmpty) {
      return buildChapterTiles(mainSubjectName, subjectData.chapters);
    }
    // Case 2: Sub Subjects
    else if (subjectData.subSubjects != null &&
        subjectData.subSubjects!.isNotEmpty) {
      List<Widget> subSubjectWidgets = [];
      subjectData.subSubjects!.forEach((subSubjectName, subSubjectData) {
        subSubjectWidgets.add(Padding(
            padding: EdgeInsets.only(
                top: 10.0, bottom: 4.0, left: subSubjectIndent + 16.0),
            child: Text(subSubjectName,
                style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: accentCyan)))); // Use accent for sub-subject
        subSubjectWidgets.addAll(buildChapterTiles(
            subSubjectName,
            subSubjectData
                .chapters)); // Recursive call or pass sub-subject name
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
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: textSecondary)))
      ];
    }
  }

  // Helper to build ListTile for each chapter
  Widget _buildChapterTile(BuildContext context, WidgetRef ref,
      String subjectName, ChapterDetailed chapter, double indent) {
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
      contentPadding: EdgeInsets.only(
          left: indent + 16.0, right: 8), // Apply dynamic indent
      title: Text(chapter.chapterTitle,
          style: textTheme.bodyLarge?.copyWith(color: textPrimary)),
      subtitle: Text("Status: $progressText",
          style: textTheme.bodySmall?.copyWith(color: textSecondary)),
      leading: Icon(
          isMastered ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 18,
          color: isMastered
              ? Colors.green.shade400
              : primaryPurple.withOpacity(0.8)),
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 20, color: textSecondary),
      onTap: () {
        print(
            "Tapped Chapter: ${chapter.chapterTitle} (ID: ${chapter.chapterId}), Subject: $subjectName");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChapterLandingScreen(
                    subjectName: subjectName, chapterId: chapter.chapterId)));
      },
    );
  }

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

  // Helper Widgets for Shimmer/Error (Dark theme adjustment needed)
  Widget _buildShimmerCard(
      {required double height, double? width, double borderRadius = 15}) {
    return Shimmer.fromColors(
        baseColor: surfaceLight,
        highlightColor: surfaceLight.withOpacity(0.5),
        child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
                color: Colors.white /* Needs placeholder color */,
                borderRadius: BorderRadius.circular(borderRadius))));
  }

  Widget _buildShimmerText(double width, double height) {
    return Shimmer.fromColors(
        baseColor: surfaceLight,
        highlightColor: surfaceLight.withOpacity(0.5),
        child: Container(
            width: width,
            height: height,
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 2)));
  }

  Widget _buildShimmerAvatar(double radius) {
    return Shimmer.fromColors(
        baseColor: surfaceLight,
        highlightColor: surfaceLight.withOpacity(0.5),
        child: CircleAvatar(radius: radius, backgroundColor: Colors.white));
  }

  Widget _buildErrorCard(BuildContext context, String message, Object error,
      VoidCallback onRetry) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
        color: colorScheme.errorContainer.withOpacity(0.7),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(12),
            child: Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.warning_amber_rounded,
                      color: colorScheme.onErrorContainer, size: 30),
                  const SizedBox(height: 10),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: textTheme.titleSmall
                          ?.copyWith(color: colorScheme.onErrorContainer)),
                  const SizedBox(height: 4),
                  Text(error.toString(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer.withOpacity(0.8)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text("Retry"),
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError))
                ])))));
  }

  Widget _buildInfoCard(BuildContext context, String title, String message,
      IconData icon, Color color) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
        color: surfaceLight.withOpacity(0.7),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(message,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: textSecondary))
                  ]))
            ])));
  }
} // End of SyllabusScreen class
// --- End of SyllabusScreen class ---
