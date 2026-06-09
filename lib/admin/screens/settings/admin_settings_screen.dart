import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_settings_provider.dart';
import '../../models/app_settings_model.dart';
import '../../widgets/admin_section_header.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_button.dart';
import '../../../widgets/premium_textfield.dart';
import '../../../widgets/premium_loading.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _appNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _privacyController;
  late final TextEditingController _termsController;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController();
    _emailController = TextEditingController();
    _privacyController = TextEditingController();
    _termsController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminSettingsProvider>().fetchSettings();
    });
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _emailController.dispose();
    _privacyController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _save(BuildContext context, AdminSettingsProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final updated = AppSettingsModel(
      appName: _appNameController.text.trim(),
      contactEmail: _emailController.text.trim(),
      privacyPolicy: _privacyController.text.trim(),
      termsAndConditions: _termsController.text.trim(),
    );

    final success = await provider.saveSettings(updated);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App configuration saved successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: ${provider.error ?? 'Unknown error'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminSettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.status == AdminSettingsStatus.loaded && !_isInitialized) {
      _appNameController.text = provider.settings.appName;
      _emailController.text = provider.settings.contactEmail;
      _privacyController.text = provider.settings.privacyPolicy;
      _termsController.text = provider.settings.termsAndConditions;
      _isInitialized = true;
    }

    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: isMobile ? AppSizes.pagePadding : AppSizes.pagePaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionHeader(
              title: 'Global Settings',
              subtitle: 'Configure support contacts, company name metadata, and legal agreements.',
            ),
            SizedBox(height: AppSizes.s24),
            Expanded(
              child: provider.isLoading && !_isInitialized
                  ? const PageShimmer(itemCount: 3)
                  : SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: GlassCard(
                            padding: EdgeInsets.all(isMobile ? AppSizes.s16 : AppSizes.s24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(AppSizes.s10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                        ),
                                        child: Icon(Icons.settings_rounded, color: AppColors.primary, size: AppSizes.iconMd),
                                      ),
                                      SizedBox(width: AppSizes.s12),
                                      Text('Configuration', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                  SizedBox(height: AppSizes.s24),
                                  PremiumTextField(
                                    label: 'Platform Name *',
                                    controller: _appNameController,
                                    hint: 'Enter platform name',
                                    validator: (val) => val == null || val.trim().isEmpty ? 'App Name is required' : null,
                                  ),
                                  SizedBox(height: AppSizes.s20),
                                  PremiumTextField(
                                    label: 'Support Contact Email Address *',
                                    controller: _emailController,
                                    hint: 'support@domain.com',
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Email is required';
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: AppSizes.s20),
                                  PremiumTextField(
                                    label: 'Terms & Conditions',
                                    controller: _termsController,
                                    hint: 'Write Terms and Conditions here...',
                                    maxLines: 6,
                                  ),
                                  SizedBox(height: AppSizes.s20),
                                  PremiumTextField(
                                    label: 'Privacy Policy',
                                    controller: _privacyController,
                                    hint: 'Write Privacy Policy here...',
                                    maxLines: 6,
                                  ),
                                  SizedBox(height: AppSizes.s32),
                                  PremiumButton(
                                    label: 'Save Global Configuration',
                                    isLoading: provider.isSaving,
                                    onPressed: provider.isSaving ? null : () => _save(context, provider),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
