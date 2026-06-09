import 'package:flutter/material.dart';
import '../core/constants/app_sizes.dart';
import 'premium_button.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final Color? textColor;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.textColor,
    this.height = AppSizes.buttonLg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      style: isOutlined ? PremiumButtonStyle.secondary : PremiumButtonStyle.primary,
      color: color,
      textColor: textColor,
      height: height,
      icon: icon,
    );
  }
}
