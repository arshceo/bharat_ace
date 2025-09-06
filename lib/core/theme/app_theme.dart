// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors - Professional yet vibrant
  static const Color primary =
      Color(0xFF6366F1); // Indigo - trustworthy yet modern
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color primaryDark = Color(0xFF4338CA);

  // Secondary Colors - Indian-inspired
  static const Color secondary =
      Color(0xFFEC4899); // Pink - energy and creativity
  static const Color secondaryLight = Color(0xFFFDF2F8);

  // Accent Colors - Gamification
  static const Color success = Color(0xFF10B981); // Green - achievements
  static const Color warning = Color(0xFFF59E0B); // Amber - streaks
  static const Color info = Color(0xFF3B82F6); // Blue - information
  static const Color error = Color(0xFFEF4444); // Red - errors

  // Neutral Colors - Clean & Professional
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Indian Cultural Colors - Subtle integration
  static const Color saffron = Color(0xFFFF9933);
  static const Color lotus = Color(0xFFDB7093);
  static const Color emerald = Color(0xFF50C878);

  // Typography - Human-like, readable
  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: gray900,
          letterSpacing: -0.02,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: gray900,
          letterSpacing: -0.01,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: gray800,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: gray800,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: gray800,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: gray700,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: gray700,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: gray600,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: gray500,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: gray700,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: gray600,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: gray500,
        ),
      );

  // Shadows & Elevation
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: gray900.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: gray900.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: gray900.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: gray900.withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radius2XL = 32.0;

  // Spacing
  static const double space2XS = 4.0;
  static const double spaceXS = 8.0;
  static const double spaceSM = 12.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 20.0;
  static const double spaceXL = 24.0;
  static const double space2XL = 32.0;
  static const double space3XL = 48.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // Dark Mode Colors - Pure black for OLED screens and true dark theme
  static const Color darkBg = Color(0xFF000000); // Pure black background
  static const Color darkSurface =
      Color(0xFF000000); // Also pure black for surfaces
  static const Color darkCard = Color(0xFF0A0A0A); // Nearly black cards
  static const Color darkBorder = Color(0xFF181818); // Dark borders

  // Dark Theme Text Colors - Better contrast
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure white text
  static const Color darkTextSecondary = Color(0xFFCCCCCC); // Light gray text
  static const Color darkTextTertiary = Color(0xFF999999); // Medium gray text

  // Theme Data - Light Mode
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: white,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: white,
          background: white,
          error: error,
          onPrimary: white,
          onSecondary: white,
          onSurface: gray900,
          onBackground: gray900,
          onError: white,
        ),
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: white,
          foregroundColor: gray900,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: textTheme.headlineSmall,
          iconTheme: const IconThemeData(color: gray700),
        ),
        cardTheme: CardThemeData(
          color: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
            side: BorderSide(color: gray200, width: 1),
          ),
          shadowColor: gray900.withOpacity(0.04),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMD),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: spaceLG,
              vertical: spaceMD,
            ),
            textStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: gray700,
            side: const BorderSide(color: gray300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMD),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: spaceLG,
              vertical: spaceMD,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: gray50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMD),
            borderSide: const BorderSide(color: gray300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMD),
            borderSide: const BorderSide(color: gray300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMD),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spaceMD,
            vertical: spaceMD,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: gray200,
          thickness: 1,
          space: 1,
        ),
      );

  // Theme Data - Dark Mode
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        canvasColor: darkBg,
        dialogBackgroundColor: darkCard,
        colorScheme: ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: darkSurface,
          background: darkBg,
          error: error,
          onPrimary: darkTextPrimary,
          onSecondary: darkTextPrimary,
          onSurface: darkTextPrimary,
          onBackground: darkTextPrimary,
          onError: darkTextPrimary,
        ),
        textTheme: textTheme.apply(
          bodyColor: darkTextPrimary,
          displayColor: darkTextPrimary,
        ),
        cardTheme: CardThemeData(
          color: darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
            side: BorderSide(color: darkBorder, width: 1),
          ),
          shadowColor: Colors.black.withOpacity(0.2),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkSurface,
          foregroundColor: darkTextPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle:
              textTheme.headlineSmall?.copyWith(color: darkTextPrimary),
          iconTheme: IconThemeData(color: darkTextSecondary),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkSurface,
          selectedItemColor: primary,
          unselectedItemColor: darkTextTertiary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: darkTextPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMD),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: spaceLG,
              vertical: spaceMD,
            ),
            textStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkTextSecondary,
            side: BorderSide(color: darkBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMD),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: spaceLG,
              vertical: spaceMD,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMD),
            borderSide: BorderSide(color: darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMD),
            borderSide: BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMD),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spaceMD,
            vertical: spaceMD,
          ),
          labelStyle: TextStyle(color: darkTextSecondary),
          hintStyle: TextStyle(color: darkTextTertiary),
        ),
        dividerTheme: DividerThemeData(
          color: darkBorder,
          thickness: 1,
          space: 1,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radiusLG),
            ),
          ),
        ),
      );

  // Helper method to get theme-aware colors anywhere in the app
  static Color getThemeAwareColor(
      BuildContext context, Color lightColor, Color darkColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkColor
        : lightColor;
  }
}

// Component-specific styling mixins
mixin AppComponentStyles {
  // Get glass card styling based on current brightness
  static BoxDecoration getGlassCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark
        ? BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppTheme.darkBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : BoxDecoration(
            color: AppTheme.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppTheme.gray200.withOpacity(0.5)),
            boxShadow: AppTheme.cardShadow,
          );
  }

  // Legacy support for code that hasn't been updated yet
  static BoxDecoration get glassCard => BoxDecoration(
        color: AppTheme.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.gray200.withOpacity(0.5)),
        boxShadow: AppTheme.cardShadow,
      );

  // Professional white card with border and black font
  static BoxDecoration get professionalCard => BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.gray300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gray900.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: AppTheme.gray900.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      );

  static BoxDecoration get primaryGradient => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get achievementCard => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.success.withOpacity(0.1),
            AppTheme.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.success.withOpacity(0.2)),
      );
}

// Professional Card Widget
class ProfessionalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final VoidCallback? onTap;
  final bool showShadow;

  const ProfessionalCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(AppTheme.spaceLG),
      decoration: showShadow
          ? AppComponentStyles.professionalCard
          : BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: AppTheme.gray300, width: 1.5),
            ),
      child: DefaultTextStyle(
        style: AppTheme.textTheme.bodyMedium!.copyWith(
          color: AppTheme.gray900,
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}

// App Timer and Discipline System
class AppTimerManager {
  static final Map<String, DateTime> _screenStartTimes = {};
  static final Map<String, Duration> _screenTotalTimes = {};
  static DateTime? _sessionStartTime;
  static DateTime? _lastBreakTime;
  static Duration _accumulatedBreakTime = Duration.zero;
  static bool _isDisciplineMode = false;
  static const Duration disciplineSessionDuration = Duration(hours: 4);
  static const Duration breakInterval = Duration(minutes: 25);
  static const Duration breakDuration = Duration(minutes: 5);

  static void startSession() {
    _sessionStartTime = DateTime.now();
    _isDisciplineMode = false;
    _accumulatedBreakTime = Duration.zero;
    _lastBreakTime = null;
  }

  static void startScreenTimer(String screenName) {
    _screenStartTimes[screenName] = DateTime.now();
  }

  static void stopScreenTimer(String screenName) {
    final startTime = _screenStartTimes[screenName];
    if (startTime != null) {
      final sessionTime = DateTime.now().difference(startTime);
      _screenTotalTimes[screenName] =
          (_screenTotalTimes[screenName] ?? Duration.zero) + sessionTime;
      _screenStartTimes.remove(screenName);
    }
  }

  static Duration getScreenTime(String screenName) {
    final totalTime = _screenTotalTimes[screenName] ?? Duration.zero;
    final startTime = _screenStartTimes[screenName];
    if (startTime != null) {
      return totalTime + DateTime.now().difference(startTime);
    }
    return totalTime;
  }

  static Duration getSessionTime() {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  static bool shouldShowBreakDialog() {
    if (_sessionStartTime == null) return false;

    final sessionTime = getSessionTime();
    final timeSinceLastBreak = _lastBreakTime == null
        ? sessionTime
        : DateTime.now().difference(_lastBreakTime!);

    return timeSinceLastBreak >= breakInterval &&
        sessionTime < disciplineSessionDuration;
  }

  static void startBreak() {
    _lastBreakTime = DateTime.now();
  }

  static void skipBreak() {
    _accumulatedBreakTime += breakDuration;
    _lastBreakTime = DateTime.now();
  }

  static Duration getAccumulatedBreakTime() => _accumulatedBreakTime;

  static bool isDisciplineSessionActive() {
    if (_sessionStartTime == null) return false;
    return getSessionTime() < disciplineSessionDuration;
  }

  static Duration getRemainingDisciplineTime() {
    if (_sessionStartTime == null) return Duration.zero;
    final remaining = disciplineSessionDuration - getSessionTime();
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
