// lib/common/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Main colors
  static const Color primary = Color(0xFF3366FF);
  static const Color secondary = Color(0xFF002766);
  static const Color accent = Color(0xFF597EF7);

  // Text colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);

  // Warning colors
  static const Color warningRed = Color(0xFFFF4D4F);
  static const Color warningYellow = Color(0xFFFFAA00);
  static const Color accentPurple = Color(0xFFB37FEB);

  // Background colors
  static const Color background = Color(0xFFF5F6FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color disabledGrey = Color(0xFFD9D9D9);

  // Status colors
  static const Color success = Color(0xFF52C41A);
  static const Color error = Color(0xFFF5222D);
  static const Color info = Color(0xFF1890FF);
}

// App Theme Constants
class AppTheme {
  // Spacings
  static const double spaceXXS = 4.0;
  static const double spaceXS = 8.0;
  static const double spaceSM = 12.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;

  // Shadows
  static BoxShadow shadowSM = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );

  static BoxShadow shadowMD = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  static BoxShadow shadowLG = BoxShadow(
    color: Colors.black.withOpacity(0.12),
    blurRadius: 16,
    offset: const Offset(0, 8),
  );
}
