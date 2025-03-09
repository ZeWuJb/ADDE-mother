import 'package:flutter/material.dart';

class ThemeModes {
  final ThemeData lightMode = ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xffffb3c6),
      onPrimary: Colors.black45,

      secondary: Colors.blueAccent,
      onSecondary: Colors.black,

      tertiary: Color(0xFFff8fab),
      onTertiary: Colors.black,
      tertiaryContainer: Color(0xFFfb6f92),
      onTertiaryContainer: Colors.black,
      error: Colors.red,
      onError: Colors.black,
      surface: Color(0xFFFFE5EC),
      onSurface: Colors.black87,
      surfaceDim: Color(0xffffb3c6),
    ),
  );

  final ThemeData darkMode = ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.black26,
      onPrimary: Colors.white54,
      secondary: Colors.blueAccent,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: Colors.black,
      onSurface: Colors.white70,
    ),
  );
}
