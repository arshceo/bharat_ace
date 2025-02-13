import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:bharat_ace/common/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

// ✅ Onboarding Pages List
final List<Map<String, dynamic>> onboardingPages = [
  {
    "main": "Welcome!",
    "sub": "To the world's \nNo.1 Study Companion!",
    "animation": (String text) => ColorizeAnimatedText(
          text,
          colors: [
            Colors.red,
            Colors.blue,
            AppTheme.primaryColor,
            Colors.purple
          ],
          speed: const Duration(milliseconds: 1500),
          textStyle: GoogleFonts.dancingScript(
              fontSize: 55,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor),
          textAlign: TextAlign.center,
        )
  },
  {
    "main": "Ever dreamed of getting 99%?",
    "sub": "Without being overwhelmed?",
    "animation": (String text) => TyperAnimatedText(
          text,
          speed: const Duration(milliseconds: 120),
          textStyle: GoogleFonts.poppins(
              fontSize: 38,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor),
          textAlign: TextAlign.center,
        )
  },
  {
    "main": "We make studying smart & fun!",
    "sub": "Tailored just for YOU!",
    "animation": (String text) => ScaleAnimatedText(
          text,
          duration: const Duration(seconds: 3),
          textStyle: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor),
          textAlign: TextAlign.center,
        )
  },
  {
    "main": "Let's understand your level first!",
    "sub": "A small fun quiz awaits!",
    "animation": (String text) => ColorizeAnimatedText(
          text,
          colors: [Colors.red, Colors.blue, AppTheme.primaryColor],
          textStyle: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor),
          textAlign: TextAlign.center,
        )
  },
];
