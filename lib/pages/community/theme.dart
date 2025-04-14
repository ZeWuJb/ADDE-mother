import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    primaryColor: const Color(0xFFf7a1c4),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFf7a1c4),
      secondary: Color(0xFFa1c4f7),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFf7a1c4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      filled: true,
      fillColor: Colors.grey[100],
    ),
  );
}