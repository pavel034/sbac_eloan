import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1E40AF);
  static const Color secondaryColor = Color(0xFF0EA5E9);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightText = Color(0xFF1F2937);
  static const Color lightSubtext = Color(0xFF6B7280);

  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkSubtext = Color(0xFFCBD5E1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: lightSurface,
      ),
      scaffoldBackgroundColor: lightBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: lightSurface,
        foregroundColor: lightText,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        color: lightSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: lightSubtext),
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: lightText, fontWeight: FontWeight.w500),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textTheme: TextTheme(
        displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: lightText),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: lightText),
        headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: lightText),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: lightText),
        titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: lightText),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: lightText),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: lightSubtext),
        bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: lightSubtext),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: lightText),
        labelSmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: lightSubtext),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: secondaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        color: darkSurface,
      ),
      textTheme: TextTheme(
        displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: darkText),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
        headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkText),
        titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: darkText),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: darkText),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: darkSubtext),
        bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: darkSubtext),
      ),
    );
  }
}
