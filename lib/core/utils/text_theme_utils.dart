import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bharat_ace/core/theme/app_colors.dart'; // Ensure this path is correct

TextTheme getTextThemeWithFont(
    BuildContext context, String internalFontKey, double fontSizeMultiplier) {
  final TextTheme baseTextTheme = Theme.of(context).textTheme.apply(
      bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary);

  TextStyle? applyStyle(TextStyle? style) {
    if (style == null) return null;
    String googleFontsApiName;
    switch (internalFontKey) {
      case 'Roboto':
        googleFontsApiName = 'Roboto';
        break;
      case 'Lato':
        googleFontsApiName = 'Lato';
        break;
      case 'Merriweather':
        googleFontsApiName = 'Merriweather';
        break;
      case 'OpenSans':
        googleFontsApiName = 'Open Sans';
        break;
      case 'FiraCode':
        googleFontsApiName = 'Fira Code';
        break;
      case 'Nunito':
        googleFontsApiName = 'Nunito';
        break;
      case 'SourceSansPro':
        googleFontsApiName = 'Source Sans 3';
        break;
      default:
        googleFontsApiName = 'Roboto'; // Default fallback
    }
    // Ensure fonts are bundled or rely on google_fonts fetching
    return GoogleFonts.getFont(googleFontsApiName,
        textStyle: style.copyWith(
            fontSize: (style.fontSize ?? 14.0) * fontSizeMultiplier));
  }

  return baseTextTheme.copyWith(
      displayLarge: applyStyle(baseTextTheme.displayLarge),
      displayMedium: applyStyle(baseTextTheme.displayMedium),
      displaySmall: applyStyle(baseTextTheme.displaySmall),
      headlineLarge: applyStyle(baseTextTheme.headlineLarge),
      headlineMedium: applyStyle(baseTextTheme.headlineMedium),
      headlineSmall: applyStyle(baseTextTheme.headlineSmall),
      titleLarge: applyStyle(baseTextTheme.titleLarge),
      titleMedium: applyStyle(baseTextTheme.titleMedium),
      titleSmall: applyStyle(baseTextTheme.titleSmall),
      bodyLarge: applyStyle(baseTextTheme.bodyLarge),
      bodyMedium: applyStyle(baseTextTheme.bodyMedium),
      bodySmall: applyStyle(baseTextTheme.bodySmall),
      labelLarge: applyStyle(baseTextTheme.labelLarge),
      labelMedium: applyStyle(baseTextTheme.labelMedium),
      labelSmall: applyStyle(baseTextTheme.labelSmall));
}
