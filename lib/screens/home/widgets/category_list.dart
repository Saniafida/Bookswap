import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../providers/category_provider.dart';

class CategoryList extends StatefulWidget {
  final ValueChanged<String> onCategorySelected;

  const CategoryList({super.key, required this.onCategorySelected});

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  int _selectedIndex = 0;

  static IconData _iconForCategory(String name) {
    return switch (name.toLowerCase()) {
      'fiction'      => Icons.auto_awesome_rounded,
      'non-fiction'  => Icons.psychology_alt_rounded,
      'academic'     => Icons.school_rounded,
      'sci-fi'       => Icons.rocket_launch_rounded,
      'biography'    => Icons.person_rounded,
      'children'     => Icons.child_care_rounded,
      'mystery'      => Icons.search_rounded,
      'history'      => Icons.history_rounded,
      'self-help'    => Icons.self_improvement_rounded,
      _              => Icons.menu_book_rounded,
    };
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        final options = catProvider.filterOptions;
        if (_selectedIndex >= options.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedIndex = 0);
          });
        }

        return SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final isSelected = _selectedIndex == index;
              final label = options[index];
              final icon = index == 0
                  ? Icons.auto_stories_rounded
                  : _iconForCategory(label);

              return Padding(
                padding: const EdgeInsets.only(right: AppSizes.s10),
                child: GestureDetector(
                  onTap: () {
                    if (_selectedIndex == index) return;
                    setState(() => _selectedIndex = index);
                    widget.onCategorySelected(label);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppColors.primaryGradient
                          : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? AppColors.bgCardDark
                              : Colors.white)
                              .withValues(alpha: 0.85),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : AppColors.border),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? Colors.white54
                                  : AppColors.textMuted),
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
                                : (isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary),
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
