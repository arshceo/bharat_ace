import 'package:flutter/material.dart';

IconData getSubjectIcon(String subjectName) {
  String lowerSub = subjectName.toLowerCase();
  if (lowerSub.contains("math")) return Icons.calculate_rounded;
  if (lowerSub.contains("science")) return Icons.science_rounded;
  if (lowerSub.contains("physics")) return Icons.rocket_launch_outlined;
  if (lowerSub.contains("chemistry")) return Icons.biotech_rounded;
  if (lowerSub.contains("biology")) return Icons.eco_rounded;
  if (lowerSub.contains("english")) return Icons.translate_rounded;
  if (lowerSub.contains("hindi")) return Icons.translate_rounded;
  if (lowerSub.contains("social")) return Icons.public_rounded;
  if (lowerSub.contains("history")) return Icons.account_balance_rounded;
  if (lowerSub.contains("geography")) return Icons.map_rounded;
  if (lowerSub.contains("civics")) return Icons.gavel_rounded;
  if (lowerSub.contains("economic")) return Icons.insights_rounded;
  if (lowerSub.contains("computer")) return Icons.computer_rounded;
  return Icons.menu_book_rounded;
}
