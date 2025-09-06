// lib/widgets/dark_mode_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';

class DarkModeWrapper extends ConsumerWidget {
  final Widget child;

  const DarkModeWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always use dark theme
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.darkBg,
        cardColor: AppTheme.darkCard,
        canvasColor: AppTheme.darkBg,
        dialogBackgroundColor: AppTheme.darkCard,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppTheme.darkSurface,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.darkTextTertiary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.darkSurface,
          foregroundColor: AppTheme.darkTextPrimary,
          elevation: 0,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: AppTheme.darkTextPrimary,
              displayColor: AppTheme.darkTextPrimary,
            ),
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.primary,
          secondary: AppTheme.secondary,
          surface: AppTheme.darkSurface,
          background: AppTheme.darkBg,
          onBackground: AppTheme.darkTextPrimary,
          onSurface: AppTheme.darkTextPrimary,
        ),
      ),
      child: MediaQuery(
        // Using this to ensure all material widgets use dark theme colors
        data: MediaQuery.of(context).copyWith(
          platformBrightness: Brightness.dark,
        ),
        child: child,
      ),
    );
  }
}
