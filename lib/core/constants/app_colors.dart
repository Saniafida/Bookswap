import 'package:flutter/material.dart';

/// Swaply Design System — Color Tokens
/// Palette: Mulberry Wine × Soft Cream × Rose Gold
class AppColors {
  AppColors._();

  // ── Brand Core ───────────────────────────────────────────────────────────
  /// Deep mulberry wine — primary CTA, active states, headers
  static const Color primary = Color(0xFF6B1B3E);

  /// Bright pink-mulberry — gradient endpoint, highlights
  static const Color primaryLight = Color(0xFFC54B8C);

  /// Deeper wine — pressed states
  static const Color primaryDark = Color(0xFF4A0F2A);

  /// Rose gold accent
  static const Color roseGold = Color(0xFFE8A598);

  /// Warm peach tint
  static const Color rosePeach = Color(0xFFF7D6CF);

  /// Secondary muted — captions, subtle text
  static const Color secondary = Color(0xFF7A5C6E);
  static const Color secondaryLight = Color(0xFFB89DAA);
  static const Color secondaryDark = Color(0xFF4A2D3A);

  // ── Backgrounds ──────────────────────────────────────────────────────────
  /// Main scaffold background — warm cream
  static const Color bgLight = Color(0xFFFFF6E9);

  /// Card surface — frosted white
  static const Color bgCard = Color(0xFFFFFFFF);

  /// Slightly tinted surface for inputs, chips
  static const Color bgSurface = Color(0xFFFFF0E0);

  /// Inner section background
  static const Color bgSection = Color(0xFFFAEDDC);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D1B2E);
  static const Color textSecondary = Color(0xFF7A5C6E);
  static const Color textMuted = Color(0xFFB89DAA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFEDD9C8);
  static const Color divider = Color(0xFFF2E5D5);

  // ── Status ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E9E6B);
  static const Color successBg = Color(0xFFE8F7F0);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFF8E6);
  static const Color error = Color(0xFFD94F70);
  static const Color errorBg = Color(0xFFFFEBF0);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEFF6FF);

  // ── Listing Type Colors ───────────────────────────────────────────────────
  static const Color typeSell = Color(0xFF2E9E6B);       // Green
  static const Color typeExchange = Color(0xFF3B82F6);   // Blue
  static const Color typeDonate = Color(0xFFD94F70);     // Rose
  static const Color typeSellExchange = Color(0xFF7C4DFF); // Purple

  // ── Gradients ─────────────────────────────────────────────────────────────
  /// Primary mulberry → pink gradient — buttons, FAB, active pills
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B1B3E), Color(0xFFC54B8C)],
  );

  /// Soft pink gradient for subtle backgrounds
  static const LinearGradient softPinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF6E9), Color(0xFFFFE8F0)],
  );

  /// Rose gold shimmer for accents
  static const LinearGradient roseGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8A598), Color(0xFFF7C9C0)],
  );

  /// Warm cream gradient for hero/header backgrounds
  static const LinearGradient creamGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF6E9), Color(0xFFFFF0E0)],
  );

  /// Dark mulberry for splash screen
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D0F22), Color(0xFF6B1B3E), Color(0xFF8B2352)],
  );

  /// Shimmer effect
  static LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.0),
      Colors.white.withValues(alpha: 0.08),
      Colors.white.withValues(alpha: 0.0),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // ── Glass Decorations ─────────────────────────────────────────────────────
  /// Standard frosted glass card — cream/white
  static BoxDecoration glassLight = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.82),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.60),
      width: 1,
    ),
    boxShadow: softShadow,
  );

  /// Premium card with stronger shadow
  static BoxDecoration glassCard = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.90),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color(0xFFEDD9C8).withValues(alpha: 0.60),
      width: 1,
    ),
    boxShadow: cardShadow,
  );

  /// Mulberry-tinted glass — for active/selected states
  static BoxDecoration glassPrimary = BoxDecoration(
    color: const Color(0xFF6B1B3E).withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color(0xFF6B1B3E).withValues(alpha: 0.15),
      width: 1,
    ),
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  /// Soft subtle shadow for light cards
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF6B1B3E).withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF2D1B2E).withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Stronger shadow for floating cards
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF6B1B3E).withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF2D1B2E).withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Mulberry glow shadow — for primary buttons
  static List<BoxShadow> primaryGlowShadow = [
    BoxShadow(
      color: const Color(0xFF6B1B3E).withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFFC54B8C).withValues(alpha: 0.20),
      blurRadius: 40,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Kept for Dark-Mode Compatibility ─────────────────────────────────────
  // (App is light-mode only now but keeping structure intact)
  static const Color bgDark = Color(0xFF3D0F22);
  static const Color bgCardDark = Color(0xFF5A1A35);
  static const Color bgSurfaceDark = Color(0xFF4A1228);
  static const Color textPrimaryDark = Color(0xFFFFF6E9);
  static const Color textSecondaryDark = Color(0xFFE8C5D5);
  static const Color textMutedDark = Color(0xFFB89DAA);
  static const Color borderDark = Color(0xFF7A3050);
  static const Color dividerDark = Color(0xFF5A2040);

  static Color get crystalWhite => Colors.white.withValues(alpha: 0.08);
  static Color get crystalBorder => Colors.white.withValues(alpha: 0.12);
  static Color get crystalBorderBright => Colors.white.withValues(alpha: 0.20);
  static Color get crystalGlow => primary.withValues(alpha: 0.20);

  static List<BoxShadow> crystalShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
  static List<BoxShadow> crystalGlowShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  static BoxDecoration glassCrystal = BoxDecoration(
    color: const Color(0xFF6B1B3E).withValues(alpha: 0.55),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    boxShadow: crystalShadow,
  );
  static BoxDecoration glassCrystalBright = BoxDecoration(
    color: const Color(0xFF8B2352).withValues(alpha: 0.65),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // ── Helpers ───────────────────────────────────────────────────────────────
  static Color fromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
