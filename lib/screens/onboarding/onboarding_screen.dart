import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_utils.dart';
import '../../widgets/swaply_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: AppStrings.onboarding1Title,
      description: AppStrings.onboarding1Desc,
      icon: Icons.shopping_bag_rounded,
      emoji: '🛍️',
    ),
    _OnboardingPage(
      title: AppStrings.onboarding2Title,
      description: AppStrings.onboarding2Desc,
      icon: Icons.swap_horiz_rounded,
      emoji: '🔄',
    ),
    _OnboardingPage(
      title: AppStrings.onboarding3Title,
      description: AppStrings.onboarding3Desc,
      icon: Icons.favorite_rounded,
      emoji: '💝',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      AppUtils.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _onPageChanged(int i) {
    _fadeController.reset();
    _fadeController.forward();
    setState(() => _currentPage = i);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SwaplyBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s20,
                  vertical: AppSizes.s12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo mark
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppColors.primaryGlowShadow,
                      ),
                      child: const Center(
                        child: Text(
                          'S',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (_currentPage < _pages.length - 1)
                      GestureDetector(
                        onTap: () => AppUtils.pushReplacementNamed(
                            context, AppRoutes.login),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.s16,
                                vertical: AppSizes.s8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.70),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.border.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                'Skip',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Page content ───────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (_, i) => FadeTransition(
                    opacity: i == _currentPage ? _fadeAnim : const AlwaysStoppedAnimation(1.0),
                    child: _PageContent(page: _pages[i]),
                  ),
                ),
              ),

              // ── Bottom section ─────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.s24,
                  AppSizes.s16,
                  AppSizes.s24,
                  MediaQuery.of(context).padding.bottom + AppSizes.s24,
                ),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => _DotIndicator(isActive: _currentPage == i),
                      ),
                    ),
                    const SizedBox(height: AppSizes.s28),

                    // Get Started / Next button
                    _SwaplyButton(
                      label: isLast ? 'Get Started ✨' : 'Next',
                      onTap: _next,
                    ),

                    const SizedBox(height: AppSizes.s16),

                    // Login link
                    GestureDetector(
                      onTap: () => AppUtils.pushReplacementNamed(
                          context, AppRoutes.login),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page content ─────────────────────────────────────────────────────────────
class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final String emoji;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.emoji,
  });
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxHeight < 450;
        
        Widget content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isSmall) const Spacer(flex: 2),
              if (isSmall) const SizedBox(height: 24),

              // Icon circle with glass effect
              Container(
                width: isSmall ? 140 : 200,
                height: isSmall ? 140 : 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.12),
                      AppColors.roseGold.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                      child: Container(
                        width: isSmall ? 100 : 152,
                        height: isSmall ? 100 : 152,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.80),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              page.emoji,
                              style: TextStyle(fontSize: isSmall ? 36 : 52),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: isSmall ? AppSizes.s24 : AppSizes.s48),

              Text(
                page.title,
                style: GoogleFonts.poppins(
                  fontSize: isSmall ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmall ? AppSizes.s8 : AppSizes.s14),

              Text(
                page.description,
                style: GoogleFonts.poppins(
                  fontSize: isSmall ? 13 : 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.65,
                ),
                textAlign: TextAlign.center,
              ),

              if (!isSmall) const Spacer(flex: 3),
              if (isSmall) const SizedBox(height: 24),
            ],
          ),
        );

        if (isSmall) {
          return Center(
            child: SingleChildScrollView(
              child: content,
            ),
          );
        }
        
        return content;
      },
    );
  }
}

// ── Dot indicator ─────────────────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final bool isActive;

  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.s4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        gradient: isActive ? AppColors.primaryGradient : null,
        color: isActive ? null : AppColors.border,
        boxShadow: isActive ? AppColors.primaryGlowShadow : null,
      ),
    );
  }
}

// ── Primary gradient button ───────────────────────────────────────────────────
class _SwaplyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SwaplyButton({required this.label, required this.onTap});

  @override
  State<_SwaplyButton> createState() => _SwaplyButtonState();
}

class _SwaplyButtonState extends State<_SwaplyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: AppSizes.buttonLg,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            boxShadow: AppColors.primaryGlowShadow,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
