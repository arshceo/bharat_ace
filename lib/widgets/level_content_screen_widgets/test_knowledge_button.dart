import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/utils/text_theme_utils.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';

class TestKnowledgeButton extends ConsumerWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const TestKnowledgeButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String currentFontFamily = ref.watch(currentFontFamilyProvider);
    final TextTheme buttonTextTheme =
        getTextThemeWithFont(context, currentFontFamily, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).padding.bottom, // Handles notch
      ),
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withOpacity(0.97),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: ElevatedButton.icon(
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.textPrimary, strokeWidth: 2.5))
            : const Icon(Icons.checklist_rtl_rounded,
                color: AppColors.textPrimary),
        label: Text(
          isLoading ? "Loading Assessment..." : "Test Your Knowledge",
          style: buttonTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.greenSuccess,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}
