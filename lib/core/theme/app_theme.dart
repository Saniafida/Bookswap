import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTheme {
  AppTheme._();

  static const double _borderRadius = AppSizes.radiusMd;
  static const double _buttonRadius = AppSizes.radiusSm;
  static const double _cardRadius = AppSizes.radiusLg;

  // ── Swaply uses Light theme only ─────────────────────────────────────────
  static ThemeData get light => _buildSwaplyTheme();

  // Keep dark getter for compatibility — maps to light
  static ThemeData get dark => _buildSwaplyTheme();

  static ThemeData _buildSwaplyTheme() {
    const primary = AppColors.primary;           // #6B1B3E mulberry
    const primaryLight = AppColors.primaryLight; // #C54B8C pink
    const bg = AppColors.bgLight;                // #FFF6E9 cream
    const surface = AppColors.bgCard;            // #FFFFFF white
    const textColor = AppColors.textPrimary;     // #2D1B2E
    const textSecondary = AppColors.textSecondary; // #7A5C6E
    const textMuted = AppColors.textMuted;       // #B89DAA
    const borderColor = AppColors.border;        // #EDD9C8

    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      primaryContainer: Color(0xFFFFE8F0),
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.bgSurface,
      tertiary: AppColors.roseGold,
      surface: surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
      outline: borderColor,
    );

    final textTheme = _textTheme(textColor);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(
          color: textColor,
          size: AppSizes.iconMd,
        ),
      ),

      // ── Bottom Nav ────────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        selectedIconTheme: const IconThemeData(size: AppSizes.iconMd),
        unselectedIconTheme: const IconThemeData(size: AppSizes.iconMd),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          side: BorderSide(
            color: borderColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Inputs ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s20,
          vertical: AppSizes.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppSizes.buttonLg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s24,
            vertical: AppSizes.s14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          elevation: 0,
          shadowColor: primary.withValues(alpha: 0.35),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, AppSizes.buttonLg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s24,
            vertical: AppSizes.s14,
          ),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s12,
            vertical: AppSizes.s8,
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedColor: const Color(0xFFFFE8F0),
        labelStyle: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          color: primary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
      ),

      // ── Dividers ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: borderColor.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2D1B2E),
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        elevation: 0,
        modalBarrierColor: const Color(0xFF2D1B2E).withValues(alpha: 0.4),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        elevation: 0,
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),

      // ── Tab Bar ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textMuted,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return borderColor;
        }),
      ),

      // ── Checkbox ─────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        ),
        side: const BorderSide(color: borderColor, width: 1.5),
      ),

      // ── Progress ─────────────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),

      // ── Navigation Bar ────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        indicatorColor: const Color(0xFFFFE8F0),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? primary
                : textMuted,
          );
        }),
      ),

      // ── Page Transitions ─────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Typography ─────────────────────────────────────────────────────────────
  static TextTheme _textTheme(Color color) {
    return GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.8,
        height: 1.15,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.3,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.1,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.1,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.2,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
        height: 1.3,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.4,
        height: 1.3,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.5,
        height: 1.3,
      ),
    );
  }
}
