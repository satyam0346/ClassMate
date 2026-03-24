import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// ClassMate Material Design 3 theme.
/// Light and dark ThemeData — used in MaterialApp.router in main.dart.
abstract class AppTheme {

  // ── Light Theme ─────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary:       AppColors.primary,
      onPrimary:     Colors.white,
      secondary:     AppColors.accent,
      onSecondary:   Colors.white,
      surface:       AppColors.surfaceLight,
      onSurface:     AppColors.textPrimaryLight,
      error:         AppColors.error,
      onError:       Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    cardTheme: CardThemeData(
      color:         AppColors.cardLight,
      elevation:     AppSizes.elevationCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor:  AppColors.primary,
      foregroundColor:  Colors.white,
      elevation:        0,
      centerTitle:      false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color:       Colors.white,
        fontSize:    20,
        fontWeight:  FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      AppColors.surfaceLight,
      selectedItemColor:    AppColors.primary,
      unselectedItemColor:  AppColors.textSecondaryLight,
      elevation:            AppSizes.elevationNav,
      type:                 BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation:       0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical:   AppSizes.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize:   16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical:   AppSizes.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize:   16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:          true,
      fillColor:       AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical:   AppSizes.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide:   const BorderSide(color: AppColors.dividerLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide:   const BorderSide(color: AppColors.dividerLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide:   const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide:   const BorderSide(color: AppColors.error),
      ),
      labelStyle:     TextStyle(color: AppColors.textSecondaryLight),
      hintStyle:      TextStyle(color: AppColors.textSecondaryLight),
    ),
    textTheme: _buildTextTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation:       AppSizes.elevationFAB,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusLg)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor:    AppColors.backgroundLight,
      selectedColor:      AppColors.primary,
      labelStyle:         GoogleFonts.inter(fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color:     AppColors.dividerLight,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor:  AppColors.primary,
      contentTextStyle: GoogleFonts.inter(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ── Dark Theme ──────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:       AppColors.accentLight,
      onPrimary:     AppColors.primaryDark,
      secondary:     AppColors.accent,
      onSecondary:   AppColors.primaryDark,
      surface:       AppColors.cardDark,
      onSurface:     AppColors.textPrimaryDark,
      error:         AppColors.error,
      onError:       Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardTheme: CardThemeData(
      color:     AppColors.cardDark,
      elevation: AppSizes.elevationCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation:       0,
      centerTitle:     false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color:      AppColors.textPrimaryDark,
        fontSize:   20,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:     AppColors.cardDark,
      selectedItemColor:   AppColors.accent,
      unselectedItemColor: AppColors.textSecondaryDark,
      elevation:           AppSizes.elevationNav,
      type:                BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primaryDark,
        elevation:       0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical:   AppSizes.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize:   16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:      true,
      fillColor:   AppColors.cardDark,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical:   AppSizes.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide:   const BorderSide(color: AppColors.dividerDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide:   const BorderSide(color: AppColors.dividerDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide:   const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide:   const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
      hintStyle:  const TextStyle(color: AppColors.textSecondaryDark),
    ),
    textTheme: _buildTextTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.primaryDark,
      elevation:       AppSizes.elevationFAB,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusLg)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color:     AppColors.dividerDark,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor:  AppColors.cardDark,
      contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimaryDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ── Shared text theme builder ───────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) => TextTheme(
    // Display — Plus Jakarta Sans (headings)
    displayLarge:  GoogleFonts.plusJakartaSans(
        fontSize: 57, fontWeight: FontWeight.w700, color: primary),
    displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 45, fontWeight: FontWeight.w700, color: primary),
    displaySmall:  GoogleFonts.plusJakartaSans(
        fontSize: 36, fontWeight: FontWeight.w700, color: primary),
    // Headline
    headlineLarge:  GoogleFonts.plusJakartaSans(
        fontSize: 32, fontWeight: FontWeight.w700, color: primary),
    headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28, fontWeight: FontWeight.w600, color: primary),
    headlineSmall:  GoogleFonts.plusJakartaSans(
        fontSize: 24, fontWeight: FontWeight.w600, color: primary),
    // Title
    titleLarge:  GoogleFonts.plusJakartaSans(
        fontSize: 22, fontWeight: FontWeight.w600, color: primary),
    titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w600, color: primary),
    titleSmall:  GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w600, color: primary),
    // Body — Inter
    bodyLarge:   GoogleFonts.inter(fontSize: 16, color: primary),
    bodyMedium:  GoogleFonts.inter(fontSize: 14, color: primary),
    bodySmall:   GoogleFonts.inter(fontSize: 12, color: secondary),
    // Label
    labelLarge:  GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: primary),
    labelMedium: GoogleFonts.inter(fontSize: 12, color: secondary),
    labelSmall:  GoogleFonts.inter(fontSize: 11, color: secondary),
  );
}
