import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/utils/text_theme_utils.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';

void showReaderSettingsBottomSheet(BuildContext context) {
  // Font maps are internal to this function
  final List<String> fontFamiliesDisplay = [
    'Roboto',
    'Lato',
    'Merriweather',
    'Open Sans',
    'Fira Code',
    'Nunito',
    'Source Sans Pro'
  ];
  final Map<String, String> fontProviderMap = {
    'Roboto': 'Roboto',
    'Lato': 'Lato',
    'Merriweather': 'Merriweather',
    'Open Sans': 'OpenSans',
    'Fira Code': 'FiraCode',
    'Nunito': 'Nunito',
    'Source Sans Pro': 'SourceSansPro'
  };

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (bsc) {
      return Consumer(
        // Consumer is needed to watch and read providers
        builder: (context, ref, child) {
          double currentFontSize = ref.watch(currentFontSizeMultiplierProvider);
          String currentFontInternalKey = ref.watch(currentFontFamilyProvider);
          String currentDisplayFont = fontProviderMap.entries
              .firstWhere((entry) => entry.value == currentFontInternalKey,
                  orElse: () => fontProviderMap.entries.first)
              .key;

          final sheetTextTheme = getTextThemeWithFont(
              context, currentFontInternalKey, 1.0); // For sheet's own text

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Reader Settings",
                    style: sheetTextTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text("Font Size", style: sheetTextTheme.titleMedium),
                Slider(
                  value: currentFontSize,
                  min: 0.7,
                  max: 1.6,
                  divisions: 9,
                  activeColor: AppColors.secondaryAccent,
                  inactiveColor: AppColors.secondaryAccent.withOpacity(0.3),
                  label: "${(currentFontSize * 100).toInt()}%",
                  onChanged: (value) => ref
                      .read(currentFontSizeMultiplierProvider.notifier)
                      .state = value,
                ),
                const SizedBox(height: 15),
                Text("Font Style", style: sheetTextTheme.titleMedium),
                DropdownButtonFormField<String>(
                  value: currentDisplayFont,
                  dropdownColor: AppColors.cardLightBackground,
                  style:
                      sheetTextTheme.bodyLarge, // For dropdown items text style
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.darkBackground.withOpacity(0.5),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8)),
                  items: fontFamiliesDisplay
                      .map((String displayFamily) => DropdownMenuItem<String>(
                            value: displayFamily,
                            // Use specific font for each item in dropdown for preview
                            child: Text(displayFamily,
                                style: getTextThemeWithFont(context,
                                        fontProviderMap[displayFamily]!, 1.0)
                                    .bodyLarge
                                    ?.copyWith(fontSize: 16)),
                          ))
                      .toList(),
                  onChanged: (String? newDisplayValue) {
                    if (newDisplayValue != null &&
                        fontProviderMap.containsKey(newDisplayValue)) {
                      ref.read(currentFontFamilyProvider.notifier).state =
                          fontProviderMap[newDisplayValue]!;
                    }
                  },
                ),
                const SizedBox(height: 16), // Bottom padding
              ],
            ),
          );
        },
      );
    },
  );
}
