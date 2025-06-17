import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:bharat_ace/core/theme/app_colors.dart'; // Adjusted import

class SyllabusOverallProgressHeader extends StatelessWidget {
  final double overallProgress;
  final TextTheme textTheme;

  const SyllabusOverallProgressHeader({
    super.key,
    required this.overallProgress,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    String readinessMessage;
    String motivationalQuote;
    Color readinessColor;
    IconData readinessIcon;

    if (overallProgress >= 0.9) {
      readinessMessage = "Expert Level!";
      motivationalQuote = "You've mastered the syllabus! Phenomenal work!";
      readinessColor = AppColors.greenSuccess;
      readinessIcon = Icons.school_rounded;
    } else if (overallProgress >= 0.7) {
      readinessMessage = "Exam Ready!";
      motivationalQuote = "You're well prepared. Keep reviewing!";
      readinessColor = AppColors.greenSuccess;
      readinessIcon = Icons.check_circle_rounded;
    } else if (overallProgress >= 0.4) {
      readinessMessage = "Good Progress!";
      motivationalQuote = "Steady effort pays off. Keep pushing!";
      readinessColor = AppColors.orangeWarning;
      readinessIcon = Icons.trending_up_rounded;
    } else if (overallProgress > 0) {
      readinessMessage = "Getting Started";
      motivationalQuote = "Every chapter counts. You're on your way!";
      readinessColor = AppColors.primaryAccent;
      readinessIcon = Icons.rocket_launch_rounded;
    } else {
      readinessMessage = "Let's Begin!";
      motivationalQuote = "Your learning adventure starts now!";
      readinessColor = AppColors.textSecondary;
      readinessIcon = Icons.flag_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground,
            AppColors.darkBackground.withAlpha(200)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularPercentIndicator(
              radius: 45.0,
              lineWidth: 8.0,
              percent:
                  overallProgress.clamp(0.0, 1.0), // Ensure percent is valid
              center: Text(
                "${(overallProgress.clamp(0.0, 1.0) * 100).toInt()}%",
                style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              progressColor: AppColors.secondaryAccent,
              backgroundColor: AppColors.cardLightBackground.withOpacity(0.5),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1200,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Overall Syllabus Progress",
                  style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  motivationalQuote,
                  style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: readinessColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(readinessIcon, color: readinessColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        readinessMessage,
                        style: textTheme.bodyMedium?.copyWith(
                            color: readinessColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
