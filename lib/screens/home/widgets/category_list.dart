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
      'electronics'   => Icons.phone_android_rounded,
      'fashion'       => Icons.checkroom_rounded,
      'furniture'     => Icons.chair_rounded,
      'books'         => Icons.menu_book_rounded,
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
    const colors = [
      AppColors.primary,
      Color(0xFF3B82F6), // blue - Electronics
      Color(0xFFE11D48), // rose - Fashion
      Color(0xFF7C3AED), // purple - Furniture
      Color(0xFFD97706), // amber - Books
      Color(0xFF059669), // green - Jewelry
      Color(0xFF0891B2), // cyan - Gaming
      Color(0xFFDB2777), // pink - More
      Color(0xFF6B1B3E),
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
        final cats = catProvider.categories;

        // Build items: All + real categories + More (if > 6)
        final showMore = cats.length > 6;
        final visibleCats = showMore ? cats.take(6).toList() : cats;

        // Items list: index 0 = All, then categories, then maybe More
        final itemCount = 1 + visibleCats.length + (showMore ? 1 : 0);

        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
            physics: const BouncingScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // "All" chip
              if (index == 0) {
                return _CategoryItem(
                  icon: Icons.apps_rounded,
                  label: 'All',
                  color: AppColors.primary,
                  isSelected: _selectedIndex == 0,
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    widget.onCategorySelected(null);
                  },
                );
              }

              // "More" chip at end
              if (showMore && index == itemCount - 1) {
                return _CategoryItem(
                  icon: Icons.grid_view_rounded,
                  label: 'More',
                  color: const Color(0xFFDB2777),
                  isSelected: false,
                  onTap: () {},
                );
              }

              // Real category
              final catIndex = index - 1;
              final category = visibleCats[catIndex];
              final color = _colorForIndex(index);
              final icon = _iconForCategory(category.name);

              return _CategoryItem(
                icon: icon,
                label: category.name,
                color: color,
                isSelected: _selectedIndex == index,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  widget.onCategorySelected(category.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSizes.s14),
        child: SizedBox(
          width: 62,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon box
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.50)
                        : AppColors.border.withValues(alpha: 0.70),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : AppColors.softShadow,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s6),
              // Label
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
