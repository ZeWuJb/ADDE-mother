import 'package:flutter/material.dart';

class ThemeModes {
  static final ThemeData lightMode = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFff8fab), // Soft pink for primary actions
      onPrimary: Colors.black87,
      secondary: Color(0xFFffb3c6), // Lighter pink for secondary actions
      onSecondary: Colors.black87,
      tertiary: Color(0xFF9AE6B4), // Soft green for highlights
      onTertiary: Colors.black87,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: Color(0xFFFDE2E4), // Light pink surface
      onSurface: Colors.black87,
      outline: Colors.grey[400]!,
      shadow: Colors.black12,
      surfaceContainerHighest: Color(0xFFFCE4EC),
      onSurfaceVariant: Colors.black54,
    ),
    // Typography
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
    ),
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFFff8fab),
      foregroundColor: Colors.black87,
      elevation: 4,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFff8fab),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
    ),
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFff8fab), width: 2),
      ),
    ),
    // Card Theme
    cardTheme: CardTheme(
      color: Color(0xFFFDE2E4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static final ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF8A2BE2), // Purple for primary actions
      onPrimary: Colors.white,
      secondary: Color(0xFF6A5ACD), // Light purple for secondary actions
      onSecondary: Colors.white,
      tertiary: Color(0xFF3CB371), // Green for highlights
      onTertiary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: Color(0xFF1C1C1C), // Dark surface
      onSurface: Colors.white70,
      outline: Colors.grey[700]!,
      shadow: Colors.black38,
      surfaceContainerHighest: Color(0xFF2C2C2C),
      onSurfaceVariant: Colors.white60,
    ),
    // Typography
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
    ),
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF8A2BE2),
      foregroundColor: Colors.white,
      elevation: 4,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF8A2BE2),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
    ),
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF8A2BE2), width: 2),
      ),
    ),
    // Card Theme
    cardTheme: CardTheme(
      color: Color(0xFF2C2C2C),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
