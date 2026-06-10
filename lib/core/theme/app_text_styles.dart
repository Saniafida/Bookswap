import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1.0, height: 1.1,
  );

  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.15,
  );

  static TextStyle get displaySmall => GoogleFonts.poppins(
    fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.2,
  );

  static TextStyle get headline => GoogleFonts.poppins(
    fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.25,
  );

  static TextStyle get title => GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.4,
  );

  static TextStyle get subtitle => GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.6,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.2, height: 1.5,
  );

  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );

  static TextStyle get label => GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3,
  );

  static TextStyle get small => GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4,
  );

  static TextStyle get tiny => GoogleFonts.poppins(
    fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5,
  );

  // ── Contextual Overrides ──────────────────────────────────────────────
  static TextStyle headlineWithColor(Color color) =>
      headline.copyWith(color: color);

  static TextStyle bodyWithColor(Color color) =>
      body.copyWith(color: color);
}
