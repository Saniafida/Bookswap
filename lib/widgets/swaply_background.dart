import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Swaply animated background — floating mulberry orbs + particles.
/// Wrap any screen body with this to get the premium background effect.
///
/// Usage:
/// ```dart
/// SwaplyBackground(child: YourScreenContent())
/// ```
class SwaplyBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;
  final bool darkMode; // For splash screen (dark mulberry bg)

  const SwaplyBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.darkMode = false,
  });

  @override
  State<SwaplyBackground> createState() => _SwaplyBackgroundState();
}

class _SwaplyBackgroundState extends State<SwaplyBackground>
    with TickerProviderStateMixin {
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late AnimationController _blob3Controller;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    _blob3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    _blob3Controller.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Base gradient background ──────────────────────────────────────
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: widget.darkMode
                ? AppColors.splashGradient
                : AppColors.creamGradient,
          ),
        ),

        // ── Blob 1 — top-right mulberry orb ──────────────────────────────
        AnimatedBuilder(
          animation: _blob1Controller,
          builder: (_, __) {
            final t = _blob1Controller.value;
            final offsetX = Tween<double>(begin: -20, end: 20).transform(t);
            final offsetY = Tween<double>(begin: -15, end: 25).transform(t);
            final scale = Tween<double>(begin: 0.9, end: 1.1).transform(t);
            return Positioned(
              top: -80 + offsetY,
              right: -60 + offsetX,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: size.width * 0.55,
                  height: size.width * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (widget.darkMode
                                ? AppColors.primaryLight
                                : AppColors.primaryLight)
                            .withValues(alpha: widget.darkMode ? 0.30 : 0.18),
                        AppColors.primaryLight.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // ── Blob 2 — bottom-left rose gold orb ───────────────────────────
        AnimatedBuilder(
          animation: _blob2Controller,
          builder: (_, __) {
            final t = _blob2Controller.value;
            final offsetX = Tween<double>(begin: 10, end: -25).transform(t);
            final offsetY = Tween<double>(begin: -10, end: 20).transform(t);
            final scale = Tween<double>(begin: 1.0, end: 0.85).transform(t);
            return Positioned(
              bottom: -100 + offsetY,
              left: -80 + offsetX,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: size.width * 0.65,
                  height: size.width * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.roseGold.withValues(
                            alpha: widget.darkMode ? 0.20 : 0.15),
                        AppColors.roseGold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // ── Blob 3 — center-left small mulberry blob ──────────────────────
        AnimatedBuilder(
          animation: _blob3Controller,
          builder: (_, __) {
            final t = _blob3Controller.value;
            final offsetX = Tween<double>(begin: -15, end: 30).transform(t);
            final offsetY = Tween<double>(begin: 0, end: -30).transform(t);
            final scale = Tween<double>(begin: 0.8, end: 1.0).transform(t);
            return Positioned(
              top: size.height * 0.35 + offsetY,
              left: -40 + offsetX,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: size.width * 0.40,
                  height: size.width * 0.40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(
                            alpha: widget.darkMode ? 0.18 : 0.10),
                        AppColors.primary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // ── Particles ────────────────────────────────────────────────────
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(
                progress: _particleController.value,
                isDark: widget.darkMode,
              ),
            ),
          ),

        // ── Foreground content ────────────────────────────────────────────
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}

/// Paints soft drifting particles
class _ParticlePainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _ParticlePainter({required this.progress, required this.isDark});

  static final List<_Particle> _particles = List.generate(14, (i) {
    final rand = Random(i * 7 + 13);
    return _Particle(
      x: rand.nextDouble(),
      y: rand.nextDouble(),
      size: rand.nextDouble() * 3.5 + 1.5,
      speed: rand.nextDouble() * 0.12 + 0.04,
      phase: rand.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final yPos = size.height - (t * (size.height + 80)) - 40;
      final xPos = p.x * size.width +
          sin(t * 2 * pi + p.phase * 10) * 18;
      final alpha = (sin(t * pi)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = (isDark
                ? Colors.white
                : AppColors.primaryLight)
            .withValues(alpha: alpha * (isDark ? 0.25 : 0.18))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(xPos, yPos), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, phase;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}
