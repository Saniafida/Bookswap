import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import 'premium_button.dart';

class PremiumDialog {
  static Future<T?> show<T>(BuildContext context, {
    required Widget title,
    required Widget content,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    Color? confirmColor,
    bool dismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: dismissible,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => _PremiumDialogContent(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        confirmColor: confirmColor,
        dismissible: dismissible,
      ),
    );
  }

  static Future<T?> showFull<T>(BuildContext context, {
    required Widget child,
    bool dismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: dismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  static Future<void> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    VoidCallback? onConfirm,
    Color? confirmColor,
  }) {
    return show(context, title: Text(title), content: Text(message), confirmLabel: confirmLabel, cancelLabel: cancelLabel, onConfirm: onConfirm, confirmColor: confirmColor);
  }
}

class _PremiumDialogContent extends StatelessWidget {
  final Widget title;
  final Widget content;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final Color? confirmColor;
  final bool dismissible;

  const _PremiumDialogContent({
    required this.title,
    required this.content,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.confirmColor,
    this.dismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(AppSizes.s16),
        padding: const EdgeInsets.all(AppSizes.s24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          boxShadow: AppColors.crystalShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSizes.s20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            DefaultTextStyle(
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              child: title,
            ),
            const SizedBox(height: AppSizes.s12),
            DefaultTextStyle(
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                height: 1.5,
              ),
              child: content,
            ),
            if (confirmLabel != null || cancelLabel != null) ...[
              const SizedBox(height: AppSizes.s24),
              Row(
                children: [
                  if (cancelLabel != null)
                    Expanded(
                      child: PremiumButton(
                        label: cancelLabel!,
                        style: PremiumButtonStyle.secondary,
                        onPressed: () => Navigator.pop(context),
                        height: AppSizes.buttonMd,
                      ),
                    ),
                  if (cancelLabel != null && confirmLabel != null)
                    const SizedBox(width: AppSizes.s12),
                  if (confirmLabel != null)
                    Expanded(
                      child: PremiumButton(
                        label: confirmLabel!,
                        color: confirmColor,
                        onPressed: () {
                          onConfirm?.call();
                          Navigator.pop(context);
                        },
                        height: AppSizes.buttonMd,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
