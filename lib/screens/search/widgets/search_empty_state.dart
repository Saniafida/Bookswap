import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../providers/search_provider.dart';

class SearchEmptyState extends StatelessWidget {
  final SearchTab tab;
  final bool hasQuery;
  final bool hasFilters;
  final VoidCallback? onClearFilters;

  const SearchEmptyState({
    super.key,
    required this.tab,
    required this.hasQuery,
    required this.hasFilters,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFiltered = hasQuery || hasFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                isFiltered
                    ? Icons.search_off_rounded
                    : Icons.explore_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSizes.s24),
            Text(
              isFiltered
                  ? (tab == SearchTab.items
                      ? 'No items found'
                      : 'No people found')
                  : (tab == SearchTab.items
                      ? 'Discover items'
                      : 'Find people'),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              isFiltered
                  ? 'Try a different search or adjust your filters'
                  : (tab == SearchTab.items
                      ? 'Search by title, description, or category'
                      : 'Search by name, location, or interests'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (hasFilters && onClearFilters != null) ...[
              const SizedBox(height: AppSizes.s24),
              GestureDetector(
                onTap: onClearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s20,
                    vertical: AppSizes.s10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Clear filters',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
