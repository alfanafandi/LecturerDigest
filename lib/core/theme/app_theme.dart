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
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
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
      ),
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        // Plus Jakarta Sans for headlines
        displayLarge: GoogleFonts.plusJakartaSans(
            color: onSurface, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: GoogleFonts.plusJakartaSans(
            color: onSurface, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displaySmall: GoogleFonts.plusJakartaSans(
            color: onSurface, fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.plusJakartaSans(
            color: onSurface, fontWeight: FontWeight.w800),
        headlineSmall: GoogleFonts.plusJakartaSans(
            color: onSurface, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.plusJakartaSans(
            color: onSurface, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.plusJakartaSans(
            color: onSurface, fontWeight: FontWeight.w600),
        
        // Inter for body
        bodyLarge: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12),
        labelLarge: GoogleFonts.inter(
            color: primary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelMedium: GoogleFonts.inter(
            color: onSurfaceVariant, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.inter(
            color: onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }
}
