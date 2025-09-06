// lib/core/utils/theme_enforcer.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A utility class to enforce dark theme across all screens
class ThemeEnforcer {
  /// Wrap any scaffold background color with this method to ensure
  /// it follows the dark theme when enabled
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkBg
        : Colors.white;
  }

  /// Wrap any card background color with this method
  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkCard
        : Colors.white;
  }

  /// Wrap any surface color with this method
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkSurface
        : Colors.white;
  }

  /// Get text color based on current theme
  static Color textColor(BuildContext context, {bool secondary = false}) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return secondary ? AppTheme.darkTextSecondary : AppTheme.darkTextPrimary;
    } else {
      return secondary ? AppTheme.gray600 : AppTheme.gray900;
    }
  }

  /// Forces dark mode on a widget by wrapping it in a Theme
  static Widget forceDarkMode(Widget child) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.darkBg,
        canvasColor: AppTheme.darkBg,
        dialogBackgroundColor: AppTheme.darkCard,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.primary,
          secondary: AppTheme.secondary,
          surface: AppTheme.darkSurface,
          background: AppTheme.darkBg,
        ),
      ),
      child: child,
    );
  }
}
