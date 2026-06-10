import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../providers/category_provider.dart';

class CategoryList extends StatefulWidget {
  final ValueChanged<String?> onCategorySelected;

  const CategoryList({super.key, required this.onCategorySelected});

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  int _selectedIndex = 0;

  static IconData _iconForCategory(String name) {
    return switch (name.toLowerCase()) {
      'books'         => Icons.menu_book_rounded,
      'electronics'   => Icons.phone_android_rounded,
      'fashion'       => Icons.checkroom_rounded,
      'furniture'     => Icons.chair_rounded,
      'jewelry'       => Icons.diamond_rounded,
      'bags'          => Icons.shopping_bag_rounded,
      'gaming'        => Icons.sports_esports_rounded,
      'sports'        => Icons.sports_soccer_rounded,
      'fiction'       => Icons.auto_awesome_rounded,
      'non-fiction'   => Icons.psychology_alt_rounded,
      'academic'      => Icons.school_rounded,
      'sci-fi'        => Icons.rocket_launch_rounded,
      'biography'     => Icons.person_rounded,
      'children'      => Icons.child_care_rounded,
      'mystery'       => Icons.search_rounded,
      'history'       => Icons.history_rounded,
      'self-help'     => Icons.self_improvement_rounded,
      _               => Icons.category_rounded,
    };
  }

  static Color _colorForIndex(int index) {
    final colors = [
      AppColors.primary,
      const Color(0xFF3B82F6),
      const Color(0xFFE11D48),
      const Color(0xFF8B5CF6),
      const Color(0xFFD97706),
      const Color(0xFF059669),
      const Color(0xFF0891B2),
      const Color(0xFF7C3AED),
      const Color(0xFFDB2777),
    ];
    return colors[index % colors.length];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cp = context.read<CategoryProvider>();
      if (cp.status == CategoryStatus.initial) {
        cp.fetchCategories();
        cp.subscribeToCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        final items = catProvider.filterOptions;
        if (_selectedIndex >= items.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedIndex = 0);
          });
        }

        return SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final isSelected = _selectedIndex == index;
              final label = items[index];
              final icon = index == 0
                  ? Icons.apps_rounded
                  : _iconForCategory(label);
              final accent = _colorForIndex(index);

              return Padding(
                padding: const EdgeInsets.only(right: AppSizes.s10),
                child: GestureDetector(
                  onTap: () {
                    if (_selectedIndex == index) return;
                    setState(() => _selectedIndex = index);
                    if (index == 0) {
                      widget.onCategorySelected(null);
                    } else {
                      final category = catProvider.categories[index - 1];
                      widget.onCategorySelected(category.id);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s14, vertical: AppSizes.s8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [accent, accent.withValues(alpha: 0.75)],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.border.withValues(alpha: 0.8),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : accent.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: AppSizes.s6),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
