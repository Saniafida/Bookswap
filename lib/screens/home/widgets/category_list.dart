import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../providers/category_provider.dart';
import '../../../admin/models/category_model.dart';

class CategoryList extends StatefulWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoryList({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  static IconData _iconForCategory(String name) {
    return switch (name.toLowerCase()) {
      'electronics'   => Icons.phone_android_rounded,
      'fashion'       => Icons.checkroom_rounded,
      'clothes'       => Icons.checkroom_rounded,
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

  void _showAllCategoriesSheet(BuildContext context, List<CategoryModel> allCategories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Categories',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: allCategories.length,
                  itemBuilder: (context, index) {
                    final cat = allCategories[index];
                    final isSelected = widget.selectedCategoryId == cat.id;
                    return GestureDetector(
                      onTap: () {
                        widget.onCategorySelected(cat.id);
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFE8F0)
                                  : AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFC54B8C)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _iconForCategory(cat.name),
                                color: isSelected
                                    ? const Color(0xFFC54B8C)
                                    : AppColors.textSecondary,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFC54B8C)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        final cats = catProvider.categories;

        // Static configuration of the 6 displayed categories with colors matching the screenshot
        final items = [
          _StaticCategoryConfig(
            label: 'Electronics',
            dbName: 'Electronics',
            iconBuilder: () => _buildElectronicsIcon(),
          ),
          _StaticCategoryConfig(
            label: 'Fashion',
            dbName: 'Clothes',
            iconBuilder: () => const CustomPaint(
              size: Size(26, 26),
              painter: _ShirtPainter(),
            ),
          ),
          _StaticCategoryConfig(
            label: 'Furniture',
            dbName: 'Furniture',
            iconBuilder: () => const Icon(
              Icons.weekend_rounded,
              size: 26,
              color: Color(0xFFDE7C99), // Pink sofa
            ),
          ),
          _StaticCategoryConfig(
            label: 'Books',
            dbName: 'Books',
            iconBuilder: () => _buildBooksIcon(),
          ),
          _StaticCategoryConfig(
            label: 'Jewelry',
            dbName: 'Jewelry',
            iconBuilder: () => const CustomPaint(
              size: Size(26, 26),
              painter: _NecklacePainter(),
            ),
          ),
          _StaticCategoryConfig(
            label: 'Gaming',
            dbName: 'Gaming',
            iconBuilder: () => const CustomPaint(
              size: Size(26, 26),
              painter: _GamepadPainter(),
            ),
          ),
        ];

        // Total itemCount is 7 (6 static categories + 1 More button)
        const int itemCount = 7;

        return SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
            physics: const BouncingScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // "More" button at the end
              if (index == itemCount - 1) {
                final hasSelectedCategory = widget.selectedCategoryId != null;
                final isSelectedInStatic = items.any((item) {
                  final dbCat = cats.firstWhere(
                    (c) => c.name.toLowerCase() == item.dbName.toLowerCase(),
                    orElse: () => CategoryModel(id: '', name: '', createdAt: DateTime.now()),
                  );
                  return dbCat.id.isNotEmpty && dbCat.id == widget.selectedCategoryId;
                });
                final isMoreSelected = hasSelectedCategory && !isSelectedInStatic;

                return _CategoryItem(
                  iconWidget: const Icon(
                    Icons.grid_view_rounded,
                    size: 26,
                    color: Color(0xFF6B1B3E), // Dark mulberry more icon
                  ),
                  label: 'More',
                  isSelected: isMoreSelected,
                  onTap: () => _showAllCategoriesSheet(context, cats),
                );
              }

              // Build static category item
              final config = items[index];
              final dbCat = cats.firstWhere(
                (c) => c.name.toLowerCase() == config.dbName.toLowerCase(),
                orElse: () => CategoryModel(id: '', name: '', createdAt: DateTime.now()),
              );

              final isSelected = dbCat.id.isNotEmpty && widget.selectedCategoryId == dbCat.id;

              return _CategoryItem(
                iconWidget: config.iconBuilder(),
                label: config.label,
                isSelected: isSelected,
                onTap: () {
                  if (dbCat.id.isEmpty) return;
                  if (isSelected) {
                    widget.onCategorySelected(null);
                  } else {
                    widget.onCategorySelected(dbCat.id);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _StaticCategoryConfig {
  final String label;
  final String dbName;
  final Widget Function() iconBuilder;

  const _StaticCategoryConfig({
    required this.label,
    required this.dbName,
    required this.iconBuilder,
  });
}

class _CategoryItem extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.iconWidget,
    required this.label,
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
          width: 66,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFE8F0) // Glow pink background for selection
                      : Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFC54B8C).withValues(alpha: 0.50)
                        : const Color(0xFFEDD9C8).withValues(alpha: 0.40),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFC54B8C).withValues(alpha: 0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: const Color(0xFF6B1B3E).withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Center(
                  child: iconWidget,
                ),
              ),
              const SizedBox(height: AppSizes.s6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimary, // Always dark color matching screenshot
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom Painters for Screenshot-matching Colored Icons ────────────────────

class _ShirtPainter extends CustomPainter {
  const _ShirtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF19EB5) // Pink shirt
      ..style = PaintingStyle.fill;

    final path = Path();
    final double w = size.width;
    final double h = size.height;

    path.moveTo(w * 0.35, h * 0.15);
    path.lineTo(w * 0.2, h * 0.15);
    path.lineTo(w * 0.1, h * 0.25);
    path.lineTo(w * 0.0, h * 0.45);
    path.lineTo(w * 0.15, h * 0.52);
    path.lineTo(w * 0.22, h * 0.40);
    path.lineTo(w * 0.22, h * 0.85);
    path.lineTo(w * 0.78, h * 0.85);
    path.lineTo(w * 0.78, h * 0.40);
    path.lineTo(w * 0.85, h * 0.52);
    path.lineTo(w * 1.0, h * 0.45);
    path.lineTo(w * 0.9, h * 0.25);
    path.lineTo(w * 0.8, h * 0.15);
    path.lineTo(w * 0.65, h * 0.15);
    path.quadraticBezierTo(w * 0.5, h * 0.35, w * 0.35, h * 0.15);
    path.close();

    canvas.drawPath(path, paint);

    final collarPaint = Paint()
      ..color = const Color(0xFFDE7C99) // Darker pink collar
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final collarPath = Path();
    collarPath.moveTo(w * 0.35, h * 0.15);
    collarPath.lineTo(w * 0.48, h * 0.35);
    collarPath.lineTo(w * 0.52, h * 0.35);
    collarPath.lineTo(w * 0.65, h * 0.15);
    canvas.drawPath(collarPath, collarPaint);

    final buttonPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.5, h * 0.48), 1.5, buttonPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.62), 1.5, buttonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NecklacePainter extends CustomPainter {
  const _NecklacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final chainPaint = Paint()
      ..color = const Color(0xFFE5B583) // Soft gold chain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final chainPath = Path();
    chainPath.moveTo(w * 0.2, h * 0.2);
    chainPath.cubicTo(w * 0.3, h * 0.75, w * 0.7, h * 0.75, w * 0.8, h * 0.2);
    canvas.drawPath(chainPath, chainPaint);

    final pendantPath = Path();
    pendantPath.moveTo(w * 0.5, h * 0.56);
    pendantPath.lineTo(w * 0.62, h * 0.68);
    pendantPath.lineTo(w * 0.5, h * 0.80);
    pendantPath.lineTo(w * 0.38, h * 0.68);
    pendantPath.close();

    final pendantPaint = Paint()
      ..color = const Color(0xFFDE7C99) // Pink diamond gem
      ..style = PaintingStyle.fill;
    canvas.drawPath(pendantPath, pendantPaint);

    final loopPaint = Paint()
      ..color = const Color(0xFFE5B583)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.56), 2.5, loopPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GamepadPainter extends CustomPainter {
  const _GamepadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final bodyPaint = Paint()
      ..color = const Color(0xFF3B2D54) // Indigo/Dark Purple body
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(w * 0.25, h * 0.25);
    path.lineTo(w * 0.75, h * 0.25);
    path.quadraticBezierTo(w * 0.95, h * 0.25, w * 0.95, h * 0.55);
    path.quadraticBezierTo(w * 0.95, h * 0.85, w * 0.8, h * 0.85);
    path.quadraticBezierTo(w * 0.7, h * 0.85, w * 0.65, h * 0.65);
    path.lineTo(w * 0.35, h * 0.65);
    path.quadraticBezierTo(w * 0.3, h * 0.85, w * 0.2, h * 0.85);
    path.quadraticBezierTo(w * 0.05, h * 0.85, w * 0.05, h * 0.55);
    path.quadraticBezierTo(w * 0.05, h * 0.25, w * 0.25, h * 0.25);
    path.close();
    canvas.drawPath(path, bodyPaint);

    final dpadPaint = Paint()
      ..color = const Color(0xFF6E5D88)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.25, h * 0.45), width: 10, height: 3), dpadPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.25, h * 0.45), width: 3, height: 10), dpadPaint);

    final btnPaint = Paint()
      ..color = const Color(0xFFDE7C99) // Pink buttons
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.75, h * 0.38), 2.2, btnPaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.52), 2.2, btnPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.45), 2.2, btnPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.45), 2.2, btnPaint);

    final stickPaint = Paint()
      ..color = const Color(0xFF1E1428)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.40, h * 0.52), 4.5, stickPaint);
    canvas.drawCircle(Offset(w * 0.60, h * 0.52), 4.5, stickPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Composite Icon Builders ──────────────────────────────────────────────────

Widget _buildElectronicsIcon() {
  return Center(
    child: Container(
      width: 20,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF1E1E24), // Dark smartphone frame
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDE7C99), Color(0xFF5583E0)], // Pink-to-blue gradient screen
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    ),
  );
}

Widget _buildBooksIcon() {
  return Center(
    child: Container(
      width: 22,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFDE7C99), // Pink book cover
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(2),
          bottomLeft: Radius.circular(2),
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 3,
            top: 0,
            bottom: 0,
            width: 1.5,
            child: Container(
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          Positioned(
            left: 8,
            right: 4,
            top: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 8, height: 1.5, color: const Color(0xFFFFF6E9)),
                const SizedBox(height: 2),
                Container(width: 10, height: 1.5, color: const Color(0xFFFFF6E9)),
                const SizedBox(height: 2),
                Container(width: 6, height: 1.5, color: const Color(0xFFFFF6E9)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
