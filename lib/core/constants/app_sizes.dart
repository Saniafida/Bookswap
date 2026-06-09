import 'package:flutter/material.dart';

class AppSizes {
  AppSizes._();

  // ── 8-pt Spacing System ─────────────────────────────────────────────────
  static const double s2 = 2;
  static const double s3 = 3;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s22 = 22;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s36 = 36;
  static const double s40 = 40;
  static const double s44 = 44;
  static const double s48 = 48;
  static const double s56 = 56;
  static const double s64 = 64;
  static const double s72 = 72;
  static const double s80 = 80;

  // ── Border Radius ───────────────────────────────────────────────────────
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusFull = 999;

  // ── Icon Sizes ──────────────────────────────────────────────────────────
  static const double iconXs = 14;
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;
  static const double iconXl = 36;

  // ── Avatar Sizes ────────────────────────────────────────────────────────
  static const double avatarSm = 32;
  static const double avatarMd = 44;
  static const double avatarLg = 64;
  static const double avatarXl = 96;

  // ── Button Heights ──────────────────────────────────────────────────────
  static const double buttonSm = 36;
  static const double buttonMd = 44;
  static const double buttonLg = 52;
  static const double buttonXl = 60;

  // ── Card Widths / Breakpoints ───────────────────────────────────────────
  static const double cardMaxWidth = 400;
  static const double screenMaxWidth = 1200;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  // ── Horizontal Page Margins ─────────────────────────────────────────────
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: s20,
    vertical: s24,
  );

  static const EdgeInsets pagePaddingLarge = EdgeInsets.symmetric(
    horizontal: s24,
    vertical: s32,
  );

  // ── Standard Card Padding ───────────────────────────────────────────────
  static const EdgeInsets cardPadding = EdgeInsets.all(s20);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(s16);
  static const EdgeInsets cardPaddingLoose = EdgeInsets.all(s24);
}
