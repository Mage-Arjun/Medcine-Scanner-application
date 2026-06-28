import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Color Palette — "Luxury Clinical"
// Dark theme: deep obsidian with luminous teal primary.
// Light theme: alice blue with teal accents.
// ---------------------------------------------------------------------------

class AppColors {
  AppColors._();

  // ── Dark Backgrounds ──────────────────────────────────────────────────────
  static const bgBase    = Color(0xFF0B0B0F);
  static const bgSurface = Color(0xFF121218);
  static const bgRaised  = Color(0xFF1A1E29);

  // ── Light Backgrounds ─────────────────────────────────────────────────────
  static const lightBg    = Color(0xFFF0F8FF);
  static const lightSurf  = Color(0xFFFFFFFF);
  static const lightRaised = Color(0xFFE8F0FE);

  // ── Dark Text ─────────────────────────────────────────────────────────────
  static const ink      = Color(0xFFF1F5F9);
  static const inkMuted = Color(0xFF94A3B8);
  static const inkFaint = Color(0xFF475569);

  // ── Light Text ───────────────────────────────────────────────────────────
  static const lightInk      = Color(0xFF1A2B49);
  static const lightInkMuted = Color(0xFF5A6B89);
  static const lightInkFaint = Color(0xFF9AABC9);

  // ── Primary — Monochrome (black on light, white on dark) ─────────────────
  static Color primary(Brightness b) => b == Brightness.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  static Color primaryDim(Brightness b) => b == Brightness.dark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);
  static Color primaryFaint(Brightness b) => b == Brightness.dark ? const Color(0x1AFFFFFF) : const Color(0x1A000000);

  // ── Secondary — Neutral Grey ─────────────────────────────────────────────
  static Color secondary(Brightness b) => b == Brightness.dark ? const Color(0xFFAAAAAA) : const Color(0xFF555555);
  static Color secondaryDim(Brightness b) => b == Brightness.dark ? const Color(0xFF888888) : const Color(0xFF777777);
  static Color secondaryFaint(Brightness b) => b == Brightness.dark ? const Color(0x1AAAAAAA) : const Color(0x1A555555);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger  = Color(0xFFEF4444);

  // ── Borders ──────────────────────────────────────────────────────────────
  static const border       = Color(0xFF1E293B);
  static const lightBorder  = Color(0xFFD0D8E8);
  static Color borderAccent(Brightness b) => primary(b).withValues(alpha: 0.5);

  // ── Glass / Frost Tokens (matte finish) ──────────────────────────────────
  static const glassWhite      = Color(0xCCFFFFFF);
  static const glassWhiteLight = Color(0xDDFFFFFF);
  static const glassDark       = Color(0xBB000000);
  static const glassDarkLight  = Color(0xCC000000);
  static const glassBorder     = Color(0x22FFFFFF);
  static const glassBorderDark = Color(0x22000000);

  // ── Aurora Glow Colors ───────────────────────────────────────────────────
  static const auroraTeal   = Color(0xFF00D4AA);
  static const auroraCoral  = Color(0xFFFF6B6B);
  static const auroraViolet = Color(0xFF7C5CFC);
  static const auroraBlue   = Color(0xFF4A9EFF);

  // ── Functional Accents ───────────────────────────────────────────────────
  static const safeGreen        = Color(0xFF2DD4A0);
  static const warningAmber     = Color(0xFFF59E0B);
  static const metadataLavender = Color(0xFFA78BFA);
  static const coralDanger      = Color(0xFFFF6B6B);

  // ── Theme-aware helpers ──────────────────────────────────────────────────
  static Color bg(Brightness b) => b == Brightness.light ? lightBg : bgBase;
  static Color surface(Brightness b) => b == Brightness.light ? lightSurf : bgSurface;
  static Color raised(Brightness b) => b == Brightness.light ? lightRaised : bgRaised;
  static Color text(Brightness b) => b == Brightness.light ? lightInk : ink;
  static Color textMuted(Brightness b) => b == Brightness.light ? lightInkMuted : inkMuted;
  static Color textFaint(Brightness b) => b == Brightness.light ? lightInkFaint : inkFaint;
  static Color borderColor(Brightness b) => b == Brightness.light ? lightBorder : border;
  static Color glass(Brightness b) => b == Brightness.light ? glassWhiteLight : glassDark;
  static Color glassBorderColor(Brightness b) => b == Brightness.light ? glassBorderDark : glassBorder;

  // ── Glow ─────────────────────────────────────────────────────────────────
  static Color glow(Brightness b, {double alpha = 0.15}) => primary(b).withValues(alpha: alpha);
}

// ---------------------------------------------------------------------------
// Design Tokens
// ---------------------------------------------------------------------------

class AppSpacing {
  AppSpacing._();
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double pill = 100;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(Brightness b) => [
    BoxShadow(
      color: AppColors.primary(b).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> medium(Brightness b) => [
    BoxShadow(
      color: AppColors.primary(b).withValues(alpha: 0.10),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevated(Brightness b) => [
    BoxShadow(
      color: AppColors.primary(b).withValues(alpha: 0.14),
      blurRadius: 28,
      offset: const Offset(0, 8),
    ),
  ];
}

// ---------------------------------------------------------------------------
// Theme Helpers
// ---------------------------------------------------------------------------

extension ThemeColors on BuildContext {
  Brightness get _brightness => Theme.of(this).brightness;
  Color get bg => AppColors.bg(_brightness);
  Color get surface => AppColors.surface(_brightness);
  Color get raised => AppColors.raised(_brightness);
  Color get textColor => AppColors.text(_brightness);
  Color get textMuted => AppColors.textMuted(_brightness);
  Color get textFaint => AppColors.textFaint(_brightness);
  Color get borderColor => AppColors.borderColor(_brightness);
  Color get glass => AppColors.glass(_brightness);
  Color get glassBorder => AppColors.glassBorderColor(_brightness);
}

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const brightness = Brightness.dark;
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary(brightness),
      secondary: AppColors.secondary(brightness),
      surface: AppColors.bgSurface,
      error: AppColors.danger,
      onPrimary: AppColors.bgBase,
      onSecondary: AppColors.bgBase,
      onSurface: AppColors.ink,
      onError: Colors.white,
    );

    return _baseTheme(brightness, colorScheme, AppColors.bgBase);
  }

  static ThemeData get light {
    const brightness = Brightness.light;
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary(brightness),
      secondary: AppColors.secondary(brightness),
      surface: AppColors.lightSurf,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightInk,
      onError: Colors.white,
    );

    return _baseTheme(brightness, colorScheme, AppColors.lightBg);
  }

  static ThemeData _baseTheme(
    Brightness brightness,
    ColorScheme colorScheme,
    Color scaffoldBg,
  ) {
    final isDark = brightness == Brightness.dark;
    final fg = isDark ? AppColors.ink : AppColors.lightInk;
    final fgMuted = isDark ? AppColors.inkMuted : AppColors.lightInkMuted;
    final fgFaint = isDark ? AppColors.inkFaint : AppColors.lightInkFaint;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final raised = isDark ? AppColors.bgRaised : AppColors.lightRaised;
    final surface = isDark ? AppColors.bgSurface : AppColors.lightSurf;
    final primary = AppColors.primary(brightness);
    final primaryDim = AppColors.primaryDim(brightness);
    final primaryFaint = AppColors.primaryFaint(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: fgFaint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: raised,
        hintStyle: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: fgFaint,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        prefixIconColor: fgFaint,
        suffixIconColor: fgFaint,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 26,
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 20,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          color: fg,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 16,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: fg,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: fgMuted,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          color: fgFaint,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          color: fg,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          color: fgMuted,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          color: fgFaint,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          color: fg,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? AppColors.bgBase : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md + 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primaryDim, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md + 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: raised,
        contentTextStyle: GoogleFonts.inter(
          color: fg,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: border),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: fgMuted,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scaffoldBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: primaryFaint,
        selectedColor: primary,
        labelStyle: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.bgBase : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: primaryDim, width: 1),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        showCheckmark: false,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: raised,
        circularTrackColor: raised,
      ),
    );
  }
}
