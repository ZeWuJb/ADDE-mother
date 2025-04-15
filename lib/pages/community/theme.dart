import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData appTheme() {
  return ThemeData(
    primaryColor: const Color(0xFFf7a1c4), // Soft pink
    scaffoldBackgroundColor: const Color(0xFFF5F6FA), // Light grey
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFf7a1c4),
      secondary: Color(0xFFa1c4f7), // Soft blue
      surface: Colors.white,
      onSurface: Color(0xFF1A1A1A), // Dark text
    ),
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1A1A1A),
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 16,
        color: const Color(0xFF4A4A4A),
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 14,
        color: const Color(0xFF6B6B6B),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFf7a1c4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),
    cardTheme: CardTheme(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
