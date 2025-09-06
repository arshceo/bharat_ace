// lib/core/utils/theme_fix_mixin.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A mixin that provides methods to fix theme colors in existing widgets
mixin ThemeFixMixin {
  /// Returns the appropriate background color for scaffolds based on theme
  static Color getScaffoldBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkBg
        : Colors.white;
  }

  /// Returns the appropriate card color based on theme
  static Color getCardBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkCard
        : Colors.white;
  }

  /// Returns the appropriate surface color based on theme
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkSurface
        : Colors.white;
  }

  /// Returns the appropriate text color based on theme
  static Color getTextColor(BuildContext context, {bool secondary = false}) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return secondary ? AppTheme.darkTextSecondary : AppTheme.darkTextPrimary;
    } else {
      return secondary ? AppTheme.gray600 : AppTheme.gray900;
    }
  }

  /// Returns the appropriate border color based on theme
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkBorder
        : AppTheme.gray200;
  }

  /// Returns appropriate shadow for cards based on theme
  static List<BoxShadow> getCardShadow(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: AppTheme.gray900.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: AppTheme.gray900.withOpacity(0.07),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
    }
  }

  /// Creates a dark theme overlay for any widget
  static Widget wrapWithDarkTheme(Widget child) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.darkBg,
        cardColor: AppTheme.darkCard,
        canvasColor: AppTheme.darkBg,
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.darkSurface,
          foregroundColor: AppTheme.darkTextPrimary,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: AppTheme.darkTextPrimary,
              displayColor: AppTheme.darkTextPrimary,
            ),
      ),
      child: child,
    );
  }
}
