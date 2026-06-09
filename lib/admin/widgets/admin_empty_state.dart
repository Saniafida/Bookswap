// lib/admin/widgets/admin_empty_state.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/premium_button.dart';

class AdminEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AdminEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.s48, horizontal: AppSizes.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.s20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, size: 40, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
            ),
            const SizedBox(height: AppSizes.s20),
            Text(title, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.s6),
            Text(subtitle, style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.s24),
              PremiumButton(
                label: actionLabel!,
                icon: const Icon(Icons.add_rounded, size: 18),
                style: PremiumButtonStyle.glass,
                height: AppSizes.buttonMd,
                width: 200,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
