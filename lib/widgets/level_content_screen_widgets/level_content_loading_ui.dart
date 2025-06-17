import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/utils/text_theme_utils.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';

class LevelContentLoadingUI extends ConsumerWidget {
  const LevelContentLoadingUI({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String currentFontFamily = ref.watch(currentFontFamilyProvider);
    final TextTheme loadingTheme =
        getTextThemeWithFont(context, currentFontFamily, 1.0);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation(AppColors.secondaryAccent),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Guru is preparing your lesson...",
            style: loadingTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
