import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.voidBg,
      primaryColor: AppColors.foxOrange,
      cardColor: AppColors.cardBg,
      dividerColor: AppColors.borderColor,
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.voidBg,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.textSecondarySolid,
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelSmall: GoogleFonts.spaceGrotesk(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),

      colorScheme: const ColorScheme.dark(
        primary: AppColors.foxOrange,
        secondary: AppColors.accentCyan,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.foxOrange,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.foxOrange, width: 2),
        ),
        hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
        labelStyle: GoogleFonts.spaceGrotesk(color: AppColors.textSecondarySolid),
      ),
    );
  }
}
