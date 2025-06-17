import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/utils/text_theme_utils.dart';
import 'package:bharat_ace/features/level_content/controllers/level_content_controller.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';

class LevelContentErrorUI extends ConsumerWidget {
  final Object error;
  final StackTrace? stackTrace;
  final LevelContentArgs controllerArgs;
  final VoidCallback onRetry;

  const LevelContentErrorUI({
    super.key,
    required this.error,
    this.stackTrace,
    required this.controllerArgs,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String currentFontFamily = ref.watch(currentFontFamilyProvider);
    final textTheme = getTextThemeWithFont(context, currentFontFamily, 1.0);

    // You can log the error here if needed: print("Error UI: $error \n $stackTrace");

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.redFailure, size: 60),
            const SizedBox(height: 20),
            Text(
              "Oops! Something went wrong.",
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.redFailure,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Guru encountered a hiccup while preparing your lesson. Please try again.",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Retry"),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle:
                    textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
