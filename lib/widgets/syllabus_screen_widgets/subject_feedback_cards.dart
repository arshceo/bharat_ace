import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bharat_ace/core/theme/app_colors.dart'; // Adjusted import

Widget buildSyllabusErrorCard(
    BuildContext context, String message, Object error, VoidCallback onRetry) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  return Card(
    color: AppColors.cardBackground,
    elevation: 4,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: AppColors.redFailure.withOpacity(0.5), width: 1)),
    margin: const EdgeInsets.all(20),
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.redFailure, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Details: ${error.toString()}",
            textAlign: TextAlign.center,
            style:
                textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text("Try Again"),
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.redFailure,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

Widget buildSyllabusInfoCard(BuildContext context, String title, String message,
    IconData icon, Color iconColor) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  return Center(
    child: Card(
      color: AppColors.cardBackground,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 50),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5))
          ],
        ),
      ),
    )
        .animate()
        .scaleXY(begin: 0.8, duration: 400.ms, curve: Curves.elasticOut)
        .fadeIn(),
  );
}
