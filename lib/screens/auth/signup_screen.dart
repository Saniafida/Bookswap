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
import '../../widgets/glass_card.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_textfield.dart';
import 'auth_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      if (!mounted) return;
      AppUtils.showError(context, AppStrings.passwordMismatch);
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      if (!auth.isAuthenticated) {
        AppUtils.showError(
          context,
          auth.errorMessage ?? 'Please check your email to confirm your account.',
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
        backgroundColor: AppColors.bgLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSizes.pagePaddingLarge,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.cardMaxWidth),
                child: Form(
                  key: _formKey,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        const AuthBackButton(),
                        SizedBox(height: AppSizes.s24),
                        const AuthGradientLogo(
                          fontSize: 32,
                          subtitle: 'Join thousands of book lovers.',
                        ),
                        SizedBox(height: AppSizes.s28),
                        GlassCard(
                          padding: const EdgeInsets.all(AppSizes.s24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthTitle(text: 'Create Account'),
                              SizedBox(height: AppSizes.s4),
                              AuthSubtitle(
                                text: 'Fill in your details to get started.',
                              ),
                              SizedBox(height: AppSizes.s24),
                              PremiumTextField(
                                label: AppStrings.fullName,
                                hint: AppStrings.fullName,
                                controller: _nameCtrl,
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  size: AppSizes.iconSm,
                                ),
                                validator: AppUtils.validateRequired,
                              ),
                              SizedBox(height: AppSizes.s16),
                              PremiumTextField(
                                label: AppStrings.email,
                                hint: AppStrings.email,
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: AppSizes.iconSm,
                                ),
                                validator: AppUtils.validateEmail,
                              ),
                              SizedBox(height: AppSizes.s16),
                              PremiumTextField(
                                label: AppStrings.password,
                                hint: AppStrings.password,
                                controller: _passwordCtrl,
                                obscureText: true,
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  size: AppSizes.iconSm,
                                ),
                                validator: AppUtils.validatePassword,
                              ),
                              SizedBox(height: AppSizes.s16),
                              PremiumTextField(
                                label: AppStrings.confirmPassword,
                                hint: AppStrings.confirmPassword,
                                controller: _confirmCtrl,
                                obscureText: true,
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  size: AppSizes.iconSm,
                                ),
                                validator: AppUtils.validateRequired,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _register(),
                              ),
                              SizedBox(height: AppSizes.s24),
                              PremiumButton(
                                label: AppStrings.signUp,
                                onPressed: _register,
                                isLoading: auth.isLoading,
                                style: PremiumButtonStyle.primary,
                              ),
                              SizedBox(height: AppSizes.s16),
                              const AuthAgreementText(),
                              SizedBox(height: AppSizes.s20),
                              _buildOrDivider(),
                              SizedBox(height: AppSizes.s20),
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
                        SizedBox(height: AppSizes.s24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.alreadyHaveAccount,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                AppStrings.signIn,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
