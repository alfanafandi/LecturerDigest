import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors parsed from Google Stitch HTML
  static const Color primary = Color(0xFF006b5c);
  static const Color onPrimary = Color(0xFFffffff);
  static const Color primaryContainer = Color(0xFF00bfa5);
  static const Color onPrimaryContainer = Color(0xFF00473c);
  static const Color background = Color(0xFFf8f9fa);
  static const Color onBackground = Color(0xFF191c1d);
  static const Color surface = Color(0xFFf8f9fa);
  static const Color onSurface = Color(0xFF191c1d);
  static const Color onSurfaceVariant = Color(0xFF3c4a46);
  static const Color secondary = Color(0xFF005faf);
  static const Color tertiary = Color(0xFF9f4128);
  
  static const Color surfaceContainerLowest = Color(0xFFffffff);
  static const Color surfaceContainerLow = Color(0xFFf3f4f5);
  static const Color surfaceContainer = Color(0xFFedeeef);
  static const Color surfaceContainerHigh = Color(0xFFe7e8e9);
  static const Color surfaceContainerHighest = Color(0xFFe1e3e4);
  static const Color outlineVariant = Color(0xFFbbcac4);

  static ThemeData get lightTheme {
    return _buildTheme(ColorScheme.light(
      primary: primary,
      primaryContainer: primaryContainer,
      secondary: secondary,
      tertiary: tertiary,
      background: background,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: onBackground,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
    ));
  }

  static ThemeData get darkTheme {
    return _buildTheme(const ColorScheme.dark(
      primary: Color(0xFF00bfa5),
      onPrimary: Color(0xFF00382f),
      primaryContainer: Color(0xFF005044),
      onPrimaryContainer: Color(0xFF70f7de),
      secondary: Color(0xFFa6c8ff),
      onSecondary: Color(0xFF00305f),
      tertiary: Color(0xFFffb4a1),
      onTertiary: Color(0xFF601400),
      background: Color(0xFF191c1d),
      onBackground: Color(0xFFe1e3e4),
      surface: Color(0xFF191c1d),
      onSurface: Color(0xFFe1e3e4),
      onSurfaceVariant: Color(0xFFbbcac4),
      outline: Color(0xFF86938e),
    ));
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
            color: colorScheme.onSurface, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: GoogleFonts.plusJakartaSans(
            color: colorScheme.onSurface, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displaySmall: GoogleFonts.plusJakartaSans(
            color: colorScheme.onSurface, fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.plusJakartaSans(
            color: colorScheme.onSurface, fontWeight: FontWeight.w800),
        headlineSmall: GoogleFonts.plusJakartaSans(
            color: colorScheme.onSurface, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.plusJakartaSans(
            color: colorScheme.onSurface, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.plusJakartaSans(
            color: colorScheme.onSurface, fontWeight: FontWeight.w600),
        
        bodyLarge: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 12),
        labelLarge: GoogleFonts.inter(
            color: colorScheme.primary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelMedium: GoogleFonts.inter(
            color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.inter(
            color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }
}
