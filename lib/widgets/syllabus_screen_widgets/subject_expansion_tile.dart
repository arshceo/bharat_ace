import 'package:bharat_ace/core/utils/syllabus_utils.dart';
import 'package:bharat_ace/widgets/syllabus_screen_widgets/chapter_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';

class SubjectExpansionTile extends ConsumerWidget {
  final String subjectName;
  final SubjectDetailed subjectData;
  final TextTheme textTheme;
  final ({
    int total,
    int completed,
    List<ChapterDetailed> allChapters
  }) progressInfo;
  final int itemIndex; // For staggered animation

  const SubjectExpansionTile({
    super.key,
    required this.subjectName,
    required this.subjectData,
    required this.textTheme,
    required this.progressInfo,
    required this.itemIndex,
  });

  List<Widget> _buildExpansionChildren(BuildContext context, WidgetRef ref) {
    const double subSubjectIndent = 10.0;
    const double chapterIndent = 20.0;

    List<Widget> buildChapterTilesForList(
      String subjectContextForProgress,
      List<ChapterDetailed> chapters,
      double currentIndent,
    ) {
      if (chapters.isEmpty) {
        return [
          Padding(
            padding:
                EdgeInsets.only(left: currentIndent + 16.0, top: 8, bottom: 8),
            child: Text("No chapters listed for this section.",
                style: textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          )
        ];
      }
      return chapters.map((chapter) {
        int chapterIndex = chapters.indexOf(chapter);
        return ChapterTile(
          subjectNameForProgress: subjectContextForProgress,
          chapter: chapter,
          indent: currentIndent,
          textTheme: textTheme,
          key: ValueKey(
              '${subjectContextForProgress}_${chapter.chapterId}'), // Unique key for ChapterTile
        )
            .animate()
            .fadeIn(delay: (chapterIndex * 50).ms, duration: 300.ms)
            .slideX(begin: 0.1, duration: 250.ms);
      }).toList();
    }

    if (subjectData.chapters.isNotEmpty) {
      return buildChapterTilesForList(
          subjectName, subjectData.chapters, chapterIndent);
    } else if (subjectData.subSubjects != null &&
        subjectData.subSubjects?.isNotEmpty == true) {
      List<Widget> subSubjectWidgets = [];
      subjectData.subSubjects?.forEach((subSubjectName, subSubjectItemData) {
        subSubjectWidgets.add(Padding(
          padding: EdgeInsets.only(
              top: 12.0, bottom: 6.0, left: subSubjectIndent + 16.0),
          child: Text(
            subSubjectName,
            style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryAccent,
                fontSize: 17),
          ),
        ));
        subSubjectWidgets.addAll(buildChapterTilesForList(subSubjectName,
            subSubjectItemData.chapters, chapterIndent + subSubjectIndent));
        subSubjectWidgets.add(const SizedBox(height: 8));
      });
      return subSubjectWidgets;
    } else {
      // This case implies progressInfo.allChapters might also be empty,
      // or they come from a different structure not handled here.
      // The "No chapters yet" in the subtitle handles the visual cue for empty total.
      // If subjectData.chapters is empty AND subSubjects is empty/null,
      // but progressInfo.allChapters has items, it implies a data mismatch
      // or that allChapters are only used for overall progress calculation.
      // For display, we rely on subjectData.chapters and subjectData.subSubjects.
      return [
        Padding(
          padding:
              EdgeInsets.only(left: chapterIndent + 16.0, top: 8, bottom: 8),
          child: Text("No syllabus content available for this subject.",
              style: textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
        )
      ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize with a safe default
    double subjectProgress = 0.0;

    try {
      // Safely calculate progress with proper validation
      if (progressInfo.total > 0) {
        final completed = progressInfo.completed.toDouble();
        final total = progressInfo.total.toDouble();

        // Extra validation to ensure we don't get NaN or Infinity
        if (total > 0 && !completed.isNaN && !total.isNaN) {
          subjectProgress = completed / total;

          // Clamp to ensure we have a valid percentage (0.0 to 1.0)
          subjectProgress = subjectProgress.clamp(0.0, 1.0);
        }
      }

      // Final validation check
      if (subjectProgress.isNaN ||
          subjectProgress.isInfinite ||
          subjectProgress < 0) {
        print("Warning: Invalid subjectProgress calculated for $subjectName "
            "(Total: ${progressInfo.total}, Completed: ${progressInfo.completed}). Defaulting to 0.0.");
        subjectProgress = 0.0;
      }
    } catch (e) {
      print("Error calculating progress for $subjectName: $e");
      subjectProgress = 0.0;
    }

    // Debug print for indicator
    print(
        "SUBJECT_EXPANSION_TILE_INDICATOR - Subject: $subjectName, Percent: $subjectProgress, "
        "Total: ${progressInfo.total}, Completed: ${progressInfo.completed}");

    return Card(
      key: ValueKey(subjectName), // Key for the Card
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryAccent.withOpacity(0.15),
          child: Icon(getSubjectIcon(subjectName),
              color: AppColors.primaryAccent, size: 26),
        ),
        title: Text(
          subjectName,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 19,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (subjectProgress.clamp(0.0, 1.0)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${(subjectProgress * 100).toInt()}%",
                  style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (progressInfo.total == 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text("No chapters yet",
                    style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic)),
              )
          ],
        ),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 0),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: _buildExpansionChildren(context, ref),
      ),
    ).animate().fadeIn(duration: (200 + itemIndex * 80).ms).slideX(
        begin: 0.2, duration: (300 + itemIndex * 80).ms, curve: Curves.easeOut);
  }
}
