import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/search_constants.dart';
import '../../../models/post_model.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/category_provider.dart';

class SearchFilterChips extends StatelessWidget {
  const SearchFilterChips({super.key});

  Color _typeColor(ListingType type) {
    switch (type) {
      case ListingType.swap:
        return const Color(0xFF3B82F6);
      case ListingType.sell:
        return const Color(0xFF10B981);
      case ListingType.both:
        return const Color(0xFF8B5CF6);
      case ListingType.donate:
        return const Color(0xFFE11D48);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final search = context.watch<SearchProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categoryNames;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final selected = search.selectedCategory == null;
                return _GlassCategoryPill(
                  label: 'All',
                  isSelected: selected,
                  onTap: () => search.setCategory(null),
                );
              }
              final category = categories[index - 1];
              final selected = search.selectedCategory == category;
              return _GlassCategoryPill(
                label: category,
                isSelected: selected,
                onTap: () =>
                    search.setCategory(selected ? null : category),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              ...ListingType.values.map((type) {
                final selected = search.selectedListingType == type;
                final color = _typeColor(type);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _GlassFilterChip(
                    label: SearchConstants.listingTypeLabel(type),
                    selected: selected,
                    color: color,
                    onTap: () =>
                        search.setListingType(selected ? null : type),
                  ),
                );
              }),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.only(right: 8),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.border.withValues(alpha: 0.6),
              ),
              ...BookCondition.values.map((condition) {
                final selected = search.selectedCondition == condition;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _GlassFilterChip(
                    label: SearchConstants.conditionLabel(condition),
                    selected: selected,
                    color: AppColors.primary,
                    onTap: () =>
                        search.setCondition(selected ? null : condition),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassCategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassCategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s16,
            vertical: AppSizes.s8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : isDark
                    ? AppColors.bgCardDark.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.border.withValues(alpha: 0.5),
              width: isSelected ? 0 : 0.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _GlassFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s14,
            vertical: AppSizes.s6,
          ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : isDark
                  ? AppColors.bgCardDark.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.border.withValues(alpha: 0.5),
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? color
                : isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
