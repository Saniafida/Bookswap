// lib/admin/theme/admin_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class AdminTheme {
  AdminTheme._();

  static const Color primary = AppColors.primary;
  static const Color primaryLight = Color(0xFF3A3A54);
  static const Color background = AppColors.bgDark;
  static const Color surface = AppColors.bgCardDark;
  static const Color textPrimary = AppColors.textPrimaryDark;
  static const Color textSecondary = AppColors.textSecondaryDark;
  static const Color textMuted = AppColors.textMutedDark;
  static const Color border = AppColors.borderDark;
  static const Color divider = AppColors.dividerDark;

  static const Color success = AppColors.success;
  static const Color successLight = Color(0xFF065F46);
  static const Color warning = AppColors.warning;
  static const Color warningLight = Color(0xFF92400E);
  static const Color danger = AppColors.error;
  static const Color dangerLight = Color(0xFF991B1B);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> get hoverShadow => [
    BoxShadow(color: primary.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6)),
  ];

  static InputDecoration inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: textMuted, fontSize: 13, fontWeight: FontWeight.w400),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: textSecondary, size: 18) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF2D2D4A).withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border.withValues(alpha: 0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: danger, width: 1),
      ),
    );
  }

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: Color(0xFF16161F),
        error: danger,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        titleLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleMedium: GoogleFonts.poppins(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.poppins(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.poppins(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
