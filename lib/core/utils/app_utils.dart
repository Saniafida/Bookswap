import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Utility helpers used across the app.
class AppUtils {
  AppUtils._();

  // ── Snackbars ────────────────────────────────────────────────────────────
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, AppColors.success, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(context, message, AppColors.error, Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, AppColors.info, Icons.info_outline);
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ── Validators ───────────────────────────────────────────────────────────
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return AppStrings.invalidEmail;
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 6) return AppStrings.passwordTooShort;
    return null;
  }

  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    return null;
  }

  // ── Formatting ───────────────────────────────────────────────────────────
  static String formatPrice(double price) {
    if (price == 0) return 'Free';
    return '\$${price.toStringAsFixed(2)}';
  }

  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // ── Navigation helpers ───────────────────────────────────────────────────
  static void pushNamed(BuildContext context, String route, {Object? args}) {
    Navigator.pushNamed(context, route, arguments: args);
  }

  static void pushReplacementNamed(BuildContext context, String route,
      {Object? args}) {
    Navigator.pushReplacementNamed(context, route, arguments: args);
  }

  static void pushNamedAndRemoveUntil(BuildContext context, String route) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (route) => false,
    );
  }

  static void pop(BuildContext context) {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }
}
