import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Core ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF37363A);       // Crystal Indigo
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF373739);

  static const Color secondary = Color(0xFF72919F);     // Ice Blue
  static const Color secondaryLight = Color(0xFF7DD3FC);
  static const Color secondaryDark = Color(0xFF0D1213);

  // ── Crystal Dark Palette (Light Grey Crystal) ─────────────────────────
  static const Color bgDark = Color(0xFF4A494C);        // Soft dark crystal
  static const Color bgCardDark = Color(0xFF545357);    // Crystal surface
  static const Color bgSurfaceDark = Color(0xFF545357); // Elevated crystal

  static const Color textPrimaryDark = Color(0xFFF1F1F6); // Ice white
  static const Color textSecondaryDark = Color(0xFFB0B0C8); // Cool grey
  static const Color textMutedDark = Color(0xFF6E6E8A);   // Dim crystal

  static const Color borderDark = Color(0xFF3A3A54);     // Crystal edge
  static const Color dividerDark = Color(0xFF545357);    // Deep crystal seam

  // ── Crystal Frost Overlays ──────────────────────────────────────────────
  static Color get crystalWhite => Colors.white.withValues(alpha: 0.04);
  static Color get crystalBorder => Colors.white.withValues(alpha: 0.06);
  static Color get crystalBorderBright => Colors.white.withValues(alpha: 0.10);
  static Color get crystalGlow => primary.withValues(alpha: 0.15);

  // ── Status ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF065F46);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFF92400E);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFF991B1B);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF1E40AF);

  // ── Crystal Shadows ────────────────────────────────────────────────────
  static List<BoxShadow> crystalShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.30),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> crystalGlowShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  // ── Crystal Glassmorphism ──────────────────────────────────────────────
  static BoxDecoration glassCrystal = BoxDecoration(
    color: const Color(0xFF4A494C).withValues(alpha: 0.55),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.07),
    ),
    boxShadow: crystalShadow,
  );

  static BoxDecoration glassCrystalBright = BoxDecoration(
    color: const Color(0xFF85838C).withValues(alpha: 0.65),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.12),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // ── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF696770), Color(0xFF989D9F)],
  );

  static const LinearGradient crystalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF54515E), Color(0xFF85838C)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF696770), Color(0xFFC4CFD5)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF232340), Color(0xFF2D2D4A)],
  );

  static LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.0),
      Colors.white.withValues(alpha: 0.05),
      Colors.white.withValues(alpha: 0.0),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // ── Light (kept for compatibility, app uses dark) ──────────────────────
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgSurface = Color(0xFFEFF1F5);
  static const Color textPrimary = Color(0xFF0B0F19);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFFA0AEC0);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);

  static List<BoxShadow> softShadow = [
    BoxShadow(color: const Color(0xFF4A494C).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2)),
    BoxShadow(color: const Color(0xFF2F3033).withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
  ];

  static BoxDecoration glassLight = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.72),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.50)),
    boxShadow: softShadow,
  );

  // ── Helpers ────────────────────────────────────────────────────────────
  static Color fromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
