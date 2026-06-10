import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/swaply_background.dart';

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

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnim = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _glow = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
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
      body: SwaplyBackground(
        darkMode: true,
        showParticles: true,
        child: SafeArea(
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
              children: [
                const Spacer(flex: 3),

                // ── Logo ──────────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryLight.withValues(alpha: 0.40),
                            blurRadius: 50,
                            offset: const Offset(0, 12),
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: const Text(
                            'S',
                            style: TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── App name ──────────────────────────────────────────────
                Text(
                  'Swaply',
                  style: GoogleFonts.poppins(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),

                const SizedBox(height: 10),

                // ── Tagline ───────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Opacity(
                      opacity: _glow.value.clamp(0.0, 1.0),
                      child: Text(
                        'Buy • Sell • Swap • Donate',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.70),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Loading dots ─────────────────────────────────────────
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final delay = i / 3.0;
                      final t = ((_controller.value - delay + 1.0) % 1.0);
                      final alpha = (sin(t * pi)).clamp(0.0, 1.0);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                              alpha: 0.3 + alpha * 0.7),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}