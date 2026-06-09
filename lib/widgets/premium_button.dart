import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

enum PremiumButtonStyle { primary, gradient, secondary, ghost, glass }

class PremiumButton extends StatelessWidget {
  final String label;
  final Widget? icon;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final PremiumButtonStyle style;
  final double height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isLoading;
  final bool isDisabled;
  final Color? color;
  final Color? textColor;
  final double? fontSize;

  const PremiumButton({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.onPressed,
    this.style = PremiumButtonStyle.primary,
    this.height = AppSizes.buttonLg,
    this.width,
    this.padding,
    this.borderRadius = AppSizes.radiusSm,
    this.isLoading = false,
    this.isDisabled = false,
    this.color,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed =
        (isLoading || isDisabled) ? null : onPressed;

    switch (style) {
      case PremiumButtonStyle.gradient:
        return _buildGradientButton(context, effectiveOnPressed);
      case PremiumButtonStyle.glass:
        return _buildGlassButton(context, effectiveOnPressed);
      default:
        return _buildStandardButton(context, effectiveOnPressed);
    }
  }

  Widget _buildStandardButton(
    BuildContext context,
    VoidCallback? onPressed,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (style == PremiumButtonStyle.secondary) {
      return _baseButton(
        onPressed: onPressed,
        bgColor: color ?? (isDark ? AppColors.bgSurfaceDark : AppColors.bgSurface),
        textColor: textColor ?? Theme.of(context).colorScheme.onSurface,
        borderColor: AppColors.border.withValues(alpha: 0.6),
        context: context,
      );
    }

    if (style == PremiumButtonStyle.ghost) {
      return _baseButton(
        onPressed: onPressed,
        bgColor: Colors.transparent,
        textColor: textColor ?? AppColors.primary,
        borderColor: Colors.transparent,
        context: context,
        elevation: 0,
      );
    }

    // primary style
    return _baseButton(
      onPressed: onPressed,
      bgColor: color ?? AppColors.primary,
      textColor: textColor ?? Colors.white,
      context: context,
      elevation: 0,
      shadowColor: (color ?? AppColors.primary).withValues(alpha: 0.3),
    );
  }

  Widget _buildGradientButton(
    BuildContext context,
    VoidCallback? onPressed,
  ) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: _buildContent(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(
    BuildContext context,
    VoidCallback? onPressed,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.8),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Center(
                child: _buildContent(
                  textColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _baseButton({
    required VoidCallback? onPressed,
    required Color bgColor,
    required Color textColor,
    Color? borderColor,
    Color? shadowColor,
    double elevation = 0,
    required BuildContext context,
  }) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: bgColor,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
        boxShadow: shadowColor != null
            ? [BoxShadow(color: shadowColor, blurRadius: 12, offset: const Offset(0, 4))]
            : (elevation > 0 ? AppColors.softShadow : null),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: _buildContent(textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color color) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
            ),
          if (icon != null && !isLoading) ...[
            icon!,
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              isLoading ? 'Please wait...' : label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: fontSize ?? 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: color,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}
