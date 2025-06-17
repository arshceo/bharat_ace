import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/providers/progress_provider.dart';
import 'package:bharat_ace/screens/smaterial/chapter_landing_screen.dart';
import 'package:bharat_ace/core/theme/app_colors.dart'; // Adjusted import

class ChapterTile extends ConsumerWidget {
  final String subjectNameForProgress;
  final ChapterDetailed chapter;
  final double indent;
  final TextTheme textTheme;

  const ChapterTile({
    super.key,
    required this.subjectNameForProgress,
    required this.chapter,
    required this.indent,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(chapterProgressProvider(
        (subject: subjectNameForProgress, chapterId: chapter.chapterId)));

    final String progressText = progressAsync.maybeWhen(
      data: (p) => p.currentLevel ?? 'Not Started',
      loading: () => 'Loading...',
      error: (e, s) => 'Error',
      orElse: () => 'Not Started',
    );
    final bool isMastered =
        progressAsync.valueOrNull?.currentLevel == "Mastered";
    final bool isNotStarted = progressAsync.valueOrNull?.currentLevel == null ||
        progressAsync.valueOrNull?.currentLevel == "Not Started";

    IconData statusIcon;
    Color statusColor;

    if (isMastered) {
      statusIcon = Icons.check_circle_rounded;
      statusColor = AppColors.greenSuccess;
    } else if (isNotStarted) {
      statusIcon = Icons.radio_button_unchecked_rounded;
      statusColor = AppColors.textSecondary.withOpacity(0.7);
    } else {
      statusIcon = Icons.timelapse_rounded;
      statusColor = AppColors.orangeWarning;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print(
              "Tapped Chapter: ${chapter.chapterTitle} (ID: ${chapter.chapterId}), Subject Context for Progress: $subjectNameForProgress");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChapterLandingScreen(
                subjectName: subjectNameForProgress,
                chapterId: chapter.chapterId,
              ),
            ),
          );
        },
        splashColor: AppColors.primaryAccent.withOpacity(0.1),
        highlightColor: AppColors.primaryAccent.withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.only(
              left: indent + 16.0, right: 8.0, top: 8.0, bottom: 8.0),
          child: Row(
            children: [
              Icon(statusIcon, size: 22, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.chapterTitle,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    if (progressText != 'Not Started' &&
                        progressText != 'Mastered' &&
                        progressText != 'Loading...')
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          "Status: $progressText",
                          style: textTheme.bodySmall?.copyWith(
                              color: statusColor.withOpacity(0.9),
                              fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: AppColors.textSecondary.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
