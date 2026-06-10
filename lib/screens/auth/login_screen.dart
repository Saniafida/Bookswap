import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_textfield.dart';
import '../../widgets/swaply_background.dart';
import 'auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      if (auth.currentUser?.isBanned == true) {
        await auth.signOut();
        if (!mounted) return;
        AppUtils.showError(
          context,
          'Your account has been suspended. Please contact support.',
        );
        return;
      }
      if (auth.isAdmin) {
        AppUtils.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard);
      } else {
        AppUtils.pushNamedAndRemoveUntil(context, AppRoutes.bottomNav);
      }
    } else {
      AppUtils.showError(context, auth.errorMessage ?? AppStrings.genericError);
    }
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.authenticated) {
      auth.removeListener(_onAuthChanged);
      if (auth.currentUser?.isBanned == true) {
        auth.signOut();
        return;
      }
      if (auth.isAdmin) {
        AppUtils.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard);
      } else {
        AppUtils.pushNamedAndRemoveUntil(context, AppRoutes.bottomNav);
      }
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      auth.addListener(_onAuthChanged);
    } else if (auth.errorMessage != null) {
      AppUtils.showError(context, auth.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SwaplyBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: AppSizes.pagePaddingLarge,
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppSizes.cardMaxWidth),
                  child: Form(
                    key: _formKey,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 28 * (1 - value)),
                          child: child,
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSizes.s48),

                          // ── Logo ────────────────────────────────────────
                          _buildLogo(),

                          const SizedBox(height: AppSizes.s36),

                          // ── Glass card form ─────────────────────────────
                          _buildGlassCard(auth),

                          const SizedBox(height: AppSizes.s28),

                          // ── Sign up link ────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.dontHaveAccount,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => AppUtils.pushNamed(
                                    context, AppRoutes.register),
                                child: Text(
                                  ' ${AppStrings.signUp}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.s20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppColors.primaryGlowShadow,
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.s16),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: Text(
            'Swaply',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.s6),
        Text(
          AppStrings.appTagline,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(AuthProvider auth) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.s28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.6),
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back 👋',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSizes.s4),
              Text(
                'Sign in to your Swaply account',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSizes.s28),

              PremiumTextField(
                label: AppStrings.email,
                hint: 'your@email.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  size: AppSizes.iconSm,
                ),
                validator: AppUtils.validateEmail,
              ),

              const SizedBox(height: AppSizes.s16),

              PremiumTextField(
                label: AppStrings.password,
                hint: '••••••••',
                controller: _passwordCtrl,
                obscureText: true,
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: AppSizes.iconSm,
                ),
                validator: AppUtils.validatePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    AppStrings.forgotPassword,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.s4),

              PremiumButton(
                label: AppStrings.signIn,
                onPressed: _login,
                isLoading: auth.isLoading,
                style: PremiumButtonStyle.primary,
              ),

              const SizedBox(height: AppSizes.s20),
              _buildOrDivider(),
              const SizedBox(height: AppSizes.s16),

              PremiumButton(
                label: 'Continue with Google',
                icon: const GoogleIcon(),
                onPressed: _googleSignIn,
                isLoading: auth.isLoading,
                style: PremiumButtonStyle.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
          child: Text(
            'or',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
