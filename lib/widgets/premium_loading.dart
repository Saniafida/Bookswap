import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

class PremiumLoading extends StatelessWidget {
  final double size;
  final String? message;
  final Color? color;

  const PremiumLoading({
    super.key,
    this.size = 24,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: c,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSizes.s16),
            Text(
              message!,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const PremiumShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = AppSizes.radiusSm,
  });

  @override
  State<PremiumShimmer> createState() => _PremiumShimmerState();
}

class _PremiumShimmerState extends State<PremiumShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_controller.value - 1, 0),
              end: Alignment(_controller.value, 0),
              colors: [
                isDark ? AppColors.bgSurfaceDark : AppColors.bgSurface,
                isDark ? AppColors.bgCardDark : Colors.white,
                isDark ? AppColors.bgSurfaceDark : AppColors.bgSurface,
              ],
            ),
          ),
        );
      },
    );
  }
}

class PageShimmer extends StatelessWidget {
  final int itemCount;

  const PageShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppSizes.pagePadding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.s16),
      itemBuilder: (context, index) => _buildCardShimmer(context),
    );
  }

  Widget _buildCardShimmer(BuildContext context) {
    return Container(
      padding: AppSizes.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgCardDark.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumShimmer(height: 160, borderRadius: AppSizes.radiusMd),
          SizedBox(height: 16),
          PremiumShimmer(width: 200, height: 18),
          SizedBox(height: 8),
          PremiumShimmer(width: 140, height: 14),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PremiumShimmer(width: 80, height: 12),
              PremiumShimmer(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
