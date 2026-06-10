import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

/// Swaply glass card — frosted cream/white glass morphism card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final double? width;
  final double borderRadius;
  final bool hasBorder;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.height,
    this.width,
    this.borderRadius = AppSizes.radiusLg,
    this.hasBorder = true,
    this.boxShadow,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          width: width,
          margin: margin ?? EdgeInsets.zero,
          padding: padding ?? AppSizes.cardPadding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(borderRadius),
            border: hasBorder
                ? Border.all(
                    color: AppColors.border.withValues(alpha: 0.60),
                    width: 1,
                  )
                : null,
            boxShadow: boxShadow ?? AppColors.cardShadow,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

class GlassCardHeader extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final double spacing;

  const GlassCardHeader({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.spacing = AppSizes.s12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: spacing),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) title!,
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                subtitle!,
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: spacing),
          trailing!,
        ],
      ],
    );
  }
}
