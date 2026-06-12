// lib/admin/widgets/admin_stat_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class AdminStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? trend;
  final bool? isPositive;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.trend,
    this.isPositive,
    this.onTap,
  });

  @override
  State<AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<AdminStatCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _valueAnim;
  double _displayedValue = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    final parsed = double.tryParse(widget.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    _valueAnim = Tween<double>(begin: 0, end: parsed).animate(CurvedAnimation(parent: _animController, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)));
    _valueAnim.addListener(() => setState(() => _displayedValue = _valueAnim.value));
    _animController.forward();
  }

  @override
  void didUpdateWidget(AdminStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final parsed = double.tryParse(widget.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      _valueAnim = Tween<double>(begin: _displayedValue, end: parsed).animate(CurvedAnimation(parent: _animController, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)));
      _valueAnim.addListener(() => setState(() => _displayedValue = _valueAnim.value));
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsed = double.tryParse(widget.value.replaceAll(RegExp(r'[^0-9.]'), ''));

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(scale: _scaleAnim.value, child: child),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            padding: AppSizes.cardPadding,
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.4), width: 0.5),
              boxShadow: [
                BoxShadow(color: (isDark ? Colors.black : AppColors.textPrimary).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [widget.iconColor.withValues(alpha: 0.15), widget.iconColor.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(color: widget.iconColor.withValues(alpha: 0.2)),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSizes.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.title, style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSizes.s4),
                      Row(
                        textBaseline: TextBaseline.alphabetic,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        children: [
                          Flexible(
                            child: Text(
                              parsed != null ? '${_displayedValue.toInt()}' : widget.value,
                              style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.trend != null && widget.isPositive != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (widget.isPositive! ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(widget.isPositive! ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 12, color: widget.isPositive! ? AppColors.success : AppColors.error),
                                    const SizedBox(width: 2),
                                    Flexible(child: Text(widget.trend!, style: GoogleFonts.poppins(color: widget.isPositive! ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
