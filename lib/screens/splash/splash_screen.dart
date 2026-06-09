import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _glow;
  AuthProvider? _auth;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Fade animation
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Scale animation - smoother with cubic
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Slide animation for tagline
    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    // Glow pulse animation
    _glow = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _auth = context.read<AuthProvider>();
      if (_auth!.status == AuthStatus.initial) {
        _auth!.addListener(_onAuthResolved);
      } else {
        _startNavigation();
      }
    });
  }

  void _onAuthResolved() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.status != AuthStatus.initial) {
      auth.removeListener(_onAuthResolved);
      _startNavigation();
    }
  }

  Future<void> _startNavigation() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated) {
      AppUtils.pushNamedAndRemoveUntil(context, AppRoutes.onboarding);
      return;
    }

    if (auth.currentUser?.isBanned == true) {
      await auth.signOut();
      if (!mounted) return;
      AppUtils.showError(
        context,
        'Your account has been suspended. Please contact support.',
      );
      AppUtils.pushNamedAndRemoveUntil(context, AppRoutes.login);
      return;
    }

    if (auth.isAdmin) {
      AppUtils.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard);
    } else {
      AppUtils.pushNamedAndRemoveUntil(context, AppRoutes.bottomNav);
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthResolved);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background - Crystal Grey Theme
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F1419), // Deep charcoal
                  Color(0xFF1A1F2E), // Dark slate
                ],
              ),
            ),
          ),

          // Animated gradient orbs
          Positioned(
            top: -150,
            right: -100,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6B7EFF).withValues(alpha: 0.15),
                      const Color(0xFF6B7EFF).withValues(alpha: 0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B7EFF).withValues(alpha: 0.1),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -120,
            left: -80,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF5DADE2).withValues(alpha: 0.08),
                      const Color(0xFF5DADE2).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) => Opacity(
                opacity: _fadeAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: child,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo container with enhanced glassmorphism
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B7EFF).withValues(alpha: 0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 12),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF6B7EFF).withValues(alpha: 0.8),
                                const Color(0xFF5DADE2).withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(29),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App name with premium typography
                  Text(
                    'BookSwap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline with animation
                  Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Opacity(
                      opacity: _glow.value,
                      child: Text(
                        'Trade books. Grow your shelf.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.65),
                          letterSpacing: 0.3,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) {
                        return CustomPaint(
                          painter: LoadingIndicatorPainter(
                            progress: _controller.value,
                            color: const Color(0xFF6B7EFF),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom loading indicator painter
class LoadingIndicatorPainter extends CustomPainter {
  final double progress;
  final Color color;

  LoadingIndicatorPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      progress * 6.28,
      false,
      paint,
    );

    // Draw the rotating dots
    for (int i = 0; i < 3; i++) {
      final angle = (progress * 6.28) + (i * 2.09);
      final dotX = center.dx + radius * cos(angle);
      final dotY = center.dy + radius * sin(angle);

      final dotPaint = Paint()
        ..color = color.withValues(alpha: 0.7 - (i * 0.2))
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(Offset(dotX, dotY), 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(LoadingIndicatorPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// For the custom painter, import dart:math
// Add this at the top: import 'dart:math';