import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final bool centerTitle;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBack = false,
    this.centerTitle = true,
    this.height = 56,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = foregroundColor ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final bgColor = backgroundColor ?? Colors.transparent;

    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              if (leading != null)
                leading!
              else if (showBack)
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      size: AppSizes.iconSm, color: fgColor),
                  onPressed: () => Navigator.pop(context),
                )
              else
                const SizedBox(width: AppSizes.s16),
              Expanded(
                child: centerTitle
                    ? Center(
                        child: titleWidget ??
                            Text(
                              title ?? '',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: fgColor,
                              ),
                            ),
                      )
                    : titleWidget ??
                        Text(
                          title ?? '',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            color: fgColor,
                          ),
                        ),
              ),
              if (actions != null) ...[
                ...actions!,
                const SizedBox(width: AppSizes.s8),
              ] else
                const SizedBox(width: AppSizes.s16),
            ],
          ),
        ),
      ),
    );
  }
}
