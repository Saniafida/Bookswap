import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

/// Swaply premium announcement banner with glass morphism and mulberry gradient
class AnnouncementBanner extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  const AnnouncementBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bgStart = color ?? AppColors.primary;
    final bgEnd = color != null
        ? color!.withValues(alpha: 0.80)
        : AppColors.primaryLight;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgStart, bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: bgStart.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16,
              vertical: AppSizes.s12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                // Icon with glow circle
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: AppSizes.s12),
                  GestureDetector(
                    onTap: onAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s12,
                        vertical: AppSizes.s6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        actionLabel!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
