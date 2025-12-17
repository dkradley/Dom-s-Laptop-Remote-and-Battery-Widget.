import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.dark,
      background: Colors.black,
      surface: const Color(0xFF050505),
      surfaceVariant: const Color(0xFF101010),
      primary: Colors.blueAccent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFF101010),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.blueGrey, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.light,
      background: const Color(0xFFF5F5F5),
      surface: const Color(0xFFFFFFFF),
      surfaceVariant: const Color(0xFFF0F0F0),
      primary: Colors.blueAccent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F5),
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
      ),
      cardColor: Colors.white,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFAFAFA),
          foregroundColor: const Color(0xFF1A1A1A),
          side: BorderSide(color: Colors.blueGrey, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}