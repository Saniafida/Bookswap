// lib/admin/screens/categories/admin_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_category_provider.dart';
import '../../models/category_model.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_button.dart';
import '../../../widgets/premium_dialogs.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCategoryProvider>().fetchCategories();
    });
  }

  void _confirmDelete(BuildContext context, CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AdminConfirmDialog(
        title: 'Delete Category',
        content: 'Are you sure you want to delete the category "${category.name}"? This might impact filtering for listings with this category.',
        confirmLabel: 'Delete',
        isDangerous: true,
      ),
    );
    if (confirmed == true && mounted) {
      final success = await context.read<AdminCategoryProvider>().deleteCategory(category.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted successfully')));
      }
    }
  }

  void _toggleFeatured(BuildContext context, CategoryModel category, bool featured) async {
    final updated = category.copyWith(isFeatured: featured);
    final success = await context.read<AdminCategoryProvider>().updateCategory(updated);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category is now ${featured ? 'featured' : 'unfeatured'}')));
    }
  }

  void _showAddEditSheet(BuildContext context, {CategoryModel? category}) {
    PremiumDialog.showFull(context, child: _AddEditCategorySheet(category: category));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminCategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: AppSizes.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark, provider),
            const SizedBox(height: AppSizes.s24),
            Expanded(child: _buildCategoriesList(provider, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, AdminCategoryProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final addBtn = PremiumButton(
          label: 'Add Category',
          icon: const Icon(Icons.add_rounded, size: 18),
          style: PremiumButtonStyle.glass,
          width: 160,
          height: AppSizes.buttonMd,
          onPressed: () => _showAddEditSheet(context),
        );
        if (isMobile) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Categories Management', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: AppSizes.s4),
            Text('Manage listing categories, featured status, and display ordering.', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: AppSizes.s12),
            addBtn,
          ]);
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Categories Management', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: AppSizes.s4),
              Text('Manage listing categories, featured status, and display ordering.', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13)),
            ]),
            addBtn,
          ],
        );
      },
    );
  }

  Widget _buildCategoriesList(AdminCategoryProvider provider, bool isDark) {
    if (provider.isLoading && provider.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (provider.categories.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(AppSizes.s20), decoration: BoxDecoration(color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5))),
            child: Icon(Icons.category_rounded, size: 40, color: isDark ? AppColors.textMutedDark : AppColors.textMuted)),
          const SizedBox(height: AppSizes.s16),
          Text('No categories configured yet.', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : (isMobile ? 1 : 2);
        final ratio = isMobile ? 1.8 : 2.2;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: AppSizes.s16, mainAxisSpacing: AppSizes.s16, childAspectRatio: ratio),
          itemCount: provider.categories.length,
          itemBuilder: (context, index) => _buildCategoryCard(provider.categories[index], isDark),
        );
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category, bool isDark) {
    Color cardColor = AppColors.primary;
    if (category.color != null && category.color!.startsWith('#')) {
      final hex = category.color!.replaceFirst('#', '');
      final val = int.tryParse(hex, radix: 16);
      if (val != null) cardColor = Color(val | 0xFF000000);
    }

    return GlassCard(
      padding: AppSizes.cardPaddingCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: cardColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSizes.radiusSm), border: Border.all(color: cardColor.withValues(alpha: 0.2))),
                child: Icon(_getIconData(category.icon), color: cardColor, size: AppSizes.iconSm),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(child: Text(category.name, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8, vertical: AppSizes.s3),
                  decoration: BoxDecoration(color: category.isActive ? AppColors.success.withValues(alpha: 0.1) : (isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(AppSizes.radiusXs)),
                  child: Text(category.isActive ? 'Active' : 'Inactive', style: GoogleFonts.poppins(color: category.isActive ? AppColors.success : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary), fontSize: 9, fontWeight: FontWeight.w700)),
                ),
                if (category.isFeatured) ...[
                  const SizedBox(width: AppSizes.s6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8, vertical: AppSizes.s3),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.radiusXs)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded, size: 8, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text('Featured', style: GoogleFonts.poppins(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
                const SizedBox(width: AppSizes.s12),
                _buildIconBtn(Icons.star_outline_rounded, category.isFeatured ? AppColors.warning : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary), category.isFeatured ? 'Unfeature' : 'Feature', () => _toggleFeatured(context, category, !category.isFeatured)),
                const SizedBox(width: AppSizes.s4),
                _buildIconBtn(Icons.touch_app_rounded, AppColors.primary, 'Edit Display Order', null, popupMenu: List.generate(10, (i) => PopupMenuItem<int>(value: i, child: Text('Order $i', style: GoogleFonts.poppins(fontSize: 13)))), onSelected: (order) => _updateDisplayOrder(context, category, order as int)),
                _buildIconBtn(Icons.edit_outlined, AppColors.primary, 'Edit', () => _showAddEditSheet(context, category: category)),
                _buildIconBtn(Icons.delete_outline_rounded, AppColors.error, 'Delete', () => _confirmDelete(context, category)),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Text('Display Order: ${category.displayOrder}', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, String tooltip, VoidCallback? onPressed, {List<PopupMenuItem>? popupMenu, Function(dynamic)? onSelected}) {
    if (popupMenu != null) {
      return PopupMenuButton(
        icon: Icon(icon, color: color, size: AppSizes.iconSm),
        tooltip: tooltip,
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
        onSelected: onSelected,
        itemBuilder: (context) => popupMenu,
      );
    }
    return IconButton(icon: Icon(icon, color: color, size: AppSizes.iconSm), tooltip: tooltip, constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: onPressed);
  }

  void _updateDisplayOrder(BuildContext context, CategoryModel category, int order) async {
    final updated = category.copyWith(displayOrder: order);
    final success = await context.read<AdminCategoryProvider>().updateCategory(updated);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Display order updated to $order')));
    }
  }

  IconData _getIconData(String? name) {
    if (name == null) return Icons.category_rounded;
    return switch (name.toLowerCase()) {
      'book' || 'books' => Icons.book_rounded,
      'school' || 'education' => Icons.school_rounded,
      'history' => Icons.history_edu_rounded,
      'science' => Icons.science_rounded,
      'art' => Icons.palette_rounded,
      'computer' || 'tech' => Icons.computer_rounded,
      'novel' || 'fiction' => Icons.auto_stories_rounded,
      'kids' || 'children' => Icons.child_care_rounded,
      'business' => Icons.business_center_rounded,
      _ => Icons.category_rounded,
    };
  }
}

class _AddEditCategorySheet extends StatefulWidget {
  final CategoryModel? category;
  const _AddEditCategorySheet({this.category});

  @override
  State<_AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends State<_AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _iconController;
  late final TextEditingController _colorController;
  late final TextEditingController _orderController;
  bool _isFeatured = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _iconController = TextEditingController(text: widget.category?.icon ?? 'book');
    _colorController = TextEditingController(text: widget.category?.color ?? '#2563EB');
    _orderController = TextEditingController(text: (widget.category?.displayOrder ?? 0).toString());
    _isFeatured = widget.category?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    final icon = _iconController.text.trim();
    final color = _colorController.text.trim();
    final displayOrder = int.tryParse(_orderController.text) ?? 0;
    final provider = context.read<AdminCategoryProvider>();
    bool success;
    if (widget.category != null) {
      final updated = widget.category!.copyWith(name: name, icon: icon, color: color, isFeatured: _isFeatured, displayOrder: displayOrder);
      success = await provider.updateCategory(updated);
    } else {
      final newCat = CategoryModel(id: '', name: name, icon: icon, color: color, isActive: true, isFeatured: _isFeatured, displayOrder: displayOrder, createdAt: DateTime.now());
      success = await provider.addCategory(newCat);
    }
    setState(() => _isSaving = false);
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category ${widget.category != null ? 'updated' : 'added'} successfully')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save category: ${provider.error ?? 'Unknown error'}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(top: AppSizes.s24, left: AppSizes.s24, right: AppSizes.s24, bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.s24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.category != null ? 'Edit Category' : 'Create New Category', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: AppSizes.s20),
            _buildLabel('Category Name *'),
            const SizedBox(height: AppSizes.s8),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'e.g. Science Fiction',
                hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Category name is required' : null,
            ),
            const SizedBox(height: AppSizes.s16),
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel('Icon Name'),
                    const SizedBox(height: AppSizes.s8),
                    TextFormField(
                      controller: _iconController,
                      style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'e.g. book, school, art',
                        hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: AppSizes.s16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel('Color Hex'),
                    const SizedBox(height: AppSizes.s8),
                    TextFormField(
                      controller: _colorController,
                      style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: '#2563EB',
                        hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Hex code required';
                        if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(val)) return 'Must be #RRGGBB';
                        return null;
                      },
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s16),
            _buildLabel('Display Order'),
            const SizedBox(height: AppSizes.s8),
            TextFormField(
              controller: _orderController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
              ),
            ),
            const SizedBox(height: AppSizes.s12),
            Row(
              children: [
                _buildLabel('Featured Category'),
                const SizedBox(width: AppSizes.s12),
                Switch(
                  value: _isFeatured,
                  activeColor: AppColors.warning,
                  onChanged: (val) => setState(() => _isFeatured = val),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s28),
            PremiumButton(
              label: _isSaving ? 'Saving...' : (widget.category != null ? 'Update Category' : 'Create Category'),
              isLoading: _isSaving,
              style: PremiumButtonStyle.gradient,
              height: AppSizes.buttonLg,
              onPressed: _isSaving ? null : () => _save(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700));
}
