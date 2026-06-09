import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      height: height,
      width: width,
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? AppSizes.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark
                ? const Color(0xFF232340).withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.85)),
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.border.withValues(alpha: 0.4),
                width: 0.5,
              )
            : null,
        boxShadow: boxShadow ??
            (isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : AppColors.softShadow),
      ),
      child: child,
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
