import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgBase = Color(0xFF0F0E0C);
  static const bgSurface = Color(0xFF1A1815);
  static const bgRaised = Color(0xFF242119);
  static const amberGlow = Color(0xFFD4862A);
  static const amberDim = Color(0xFF8A541A);
  static const amberFaint = Color(0xFF2A1F0E);
  static const ink = Color(0xFFEDE8DF);
  static const inkMuted = Color(0xFF8C8479);
  static const inkFaint = Color(0xFF4A4540);
  static const success = Color(0xFF4E7C59);
  static const danger = Color(0xFF8C3A2E);
  static const border = Color(0xFF2E2B26);
  static const borderAccent = Color(0xFF5C4A2A);
}

class AppTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.amberGlow,
      secondary: AppColors.amberDim,
      surface: AppColors.bgSurface,
      error: AppColors.danger,
      onPrimary: AppColors.bgBase,
      onSecondary: AppColors.ink,
      onSurface: AppColors.ink,
      onError: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 18,
          color: AppColors.amberGlow,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedItemColor: AppColors.amberGlow,
        unselectedItemColor: AppColors.inkFaint,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 11,
          letterSpacing: 0.1,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 11,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgRaised,
        hintStyle: GoogleFonts.ibmPlexMono(
          fontSize: 13,
          color: AppColors.inkFaint,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.amberDim),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 34,
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 24,
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.cormorantGaramond(
          fontSize: 18,
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.cormorantGaramond(
          fontSize: 14,
          color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 15,
          color: AppColors.ink,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 13,
          color: AppColors.inkMuted,
        ),
        bodySmall: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          color: AppColors.inkFaint,
        ),
        labelLarge: GoogleFonts.ibmPlexMono(
          fontSize: 13,
          color: AppColors.inkMuted,
        ),
        labelMedium: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          color: AppColors.inkFaint,
          letterSpacing: 0.15,
        ),
        labelSmall: GoogleFonts.ibmPlexMono(
          fontSize: 10,
          color: AppColors.inkFaint,
          letterSpacing: 0.1,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amberGlow,
          foregroundColor: AppColors.bgBase,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 13,
            letterSpacing: 0.06,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.amberGlow,
          side: const BorderSide(color: AppColors.amberDim),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 13,
            letterSpacing: 0.06,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgRaised,
        contentTextStyle: GoogleFonts.dmSans(
          color: AppColors.ink,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
