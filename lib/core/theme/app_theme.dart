import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.orange,
        secondary: AppColors.butter,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
      ),
      textTheme: TextTheme(
        // Display - Bricolage Grotesque
        displayLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AppColors.ink,
        ),
        displayMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: AppColors.ink,
        ),
        displaySmall: GoogleFonts.bricolageGrotesque(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: AppColors.ink,
        ),
        // Body - Instrument Sans
        bodyLarge: GoogleFonts.instrumentSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.instrumentSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.ink2,
          height: 1.35,
        ),
        bodySmall: GoogleFonts.instrumentSans(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.ink3,
        ),
        // Monospace - Space Mono
        labelLarge: GoogleFonts.spaceMono(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: AppColors.ink,
        ),
        labelMedium: GoogleFonts.spaceMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.ink2,
        ),
        labelSmall: GoogleFonts.spaceMono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.ink3,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
    );
  }
}
