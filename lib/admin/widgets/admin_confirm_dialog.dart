// lib/admin/widgets/admin_confirm_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/premium_button.dart';

class AdminConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;

  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: AppSizes.cardPadding,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.4) : AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.s8),
                  decoration: BoxDecoration(
                    color: (isDangerous ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(isDangerous ? Icons.warning_amber_rounded : Icons.info_outline_rounded, color: isDangerous ? AppColors.error : AppColors.primary, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSizes.s12),
                Text(title, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSizes.s16),
            Text(content, style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: AppSizes.s24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  child: PremiumButton(
                    label: cancelLabel,
                    style: PremiumButtonStyle.secondary,
                    height: AppSizes.buttonMd,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                SizedBox(
                  width: 130,
                  child: PremiumButton(
                    label: confirmLabel,
                    color: isDangerous ? AppColors.error : AppColors.primary,
                    height: AppSizes.buttonMd,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
