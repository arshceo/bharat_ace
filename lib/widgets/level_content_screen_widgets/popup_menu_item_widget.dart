import 'package:flutter/material.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/utils/text_theme_utils.dart'; // Ensure this path is correct

Widget buildAppPopupMenuItem(
  BuildContext context,
  IconData icon,
  String text,
  Color iconColor,
  String currentFontFamily, // To maintain consistent font
) {
  final textTheme = getTextThemeWithFont(context, currentFontFamily, 1.0);
  return Row(
    children: [
      Icon(icon, size: 20, color: iconColor),
      const SizedBox(width: 12),
      Text(text,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
    ],
  );
}
