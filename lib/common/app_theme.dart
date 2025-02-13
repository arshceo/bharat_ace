import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFDCBABA); // Light pinkish shade
  static const Color secondaryColor =
      Color.fromARGB(255, 13, 12, 26); // Dark gray shade #0D0C17

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: primaryColor,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primaryColor: secondaryColor,
    scaffoldBackgroundColor: secondaryColor,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: secondaryColor,
      elevation: 0,
    ),
  );
}
