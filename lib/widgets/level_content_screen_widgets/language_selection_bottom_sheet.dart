import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/utils/text_theme_utils.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';
import 'package:bharat_ace/features/level_content/controllers/level_content_controller.dart'; // For TargetLanguage enum

void showLanguageSelectionSheet(
  BuildContext context,
  WidgetRef ref, // Pass ref from where it's called
  Function(TargetLanguage) onLanguageSelected, // Callback
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (bsc) {
      // No need for Consumer here if we use the passed ref
      final currentLang = ref.watch(targetLanguageProvider);
      final currentFont =
          ref.watch(currentFontFamilyProvider); // For sheet's text style
      final textTheme = getTextThemeWithFont(context, currentFont, 1.0);

      String getLanguageDisplayName(TargetLanguage lang) {
        switch (lang) {
          case TargetLanguage.english:
            return "English";
          case TargetLanguage.punjabiEnglish:
            return "Punjabi (Mixed)";
          case TargetLanguage.hindi:
            return "हिंदी (Hindi)";
          case TargetLanguage.hinglish:
            return "Hinglish";
        }
      }

      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Language",
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ...TargetLanguage.values
                .map((lang) => RadioListTile<TargetLanguage>(
                      title: Text(getLanguageDisplayName(lang),
                          style: textTheme.bodyLarge),
                      value: lang,
                      groupValue: currentLang,
                      onChanged: (TargetLanguage? value) {
                        if (value != null) {
                          onLanguageSelected(value);
                          Navigator.pop(context); // Close sheet after selection
                        }
                      },
                      activeColor: AppColors.secondaryAccent,
                      contentPadding: EdgeInsets.zero,
                    )),
            const SizedBox(height: 16), // Bottom padding
          ],
        ),
      );
    },
  );
}
