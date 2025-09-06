// lib/screens/home_screen/dark_mode_utils.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A utility class to provide theme-aware colors for the home screen
class HomeScreenTheme {
  /// Returns the appropriate text color based on theme
  static Color getTextColor(BuildContext context, {bool secondary = false}) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return secondary ? AppTheme.darkTextSecondary : AppTheme.darkTextPrimary;
    } else {
      return secondary ? AppTheme.gray600 : AppTheme.gray900;
    }
  }

  /// Returns the appropriate background color for cards based on theme
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkCard
        : Colors.white;
  }

  /// Returns the appropriate border color based on theme
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkBorder
        : AppTheme.gray200;
  }

  /// Returns the appropriate accent color based on theme
  static Color getAccentBackgroundColor(
      BuildContext context, Color lightColor) {
    if (Theme.of(context).brightness == Brightness.dark) {
      // In dark mode, make accent colors slightly transparent against dark background
      return lightColor.withOpacity(0.2);
    } else {
      return lightColor.withOpacity(0.1);
    }
  }

  /// Returns theme-aware card shadows
  static List<BoxShadow> getCardShadow(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 3),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 3),
        ),
      ];
    }
  }

  /// Creates a gradient based on theme brightness
  static LinearGradient getDarkModeGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.4),
        color.withOpacity(0.1),
      ],
    );
  }

  /// Returns a professional card decoration based on theme
  static BoxDecoration getCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: getCardColor(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      border: Border.all(
        color: getBorderColor(context),
        width: 1,
      ),
      boxShadow: getCardShadow(context),
    );
  }
}
