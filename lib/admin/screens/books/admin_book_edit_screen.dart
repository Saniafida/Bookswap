// lib/admin/screens/books/admin_book_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_book_provider.dart';
import '../../providers/admin_category_provider.dart';
import 'package:bookswap/models/post_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_button.dart';

class AdminBookEditScreen extends StatefulWidget {
  final PostModel book;
  const AdminBookEditScreen({super.key, required this.book});

  @override
  State<AdminBookEditScreen> createState() => _AdminBookEditScreenState();
}

class _AdminBookEditScreenState extends State<AdminBookEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;
  String? _category;
  late BookCondition _condition;
  late ListingType _listingType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _descController = TextEditingController(text: widget.book.description ?? '');
    _priceController = TextEditingController(text: widget.book.price?.toString() ?? '');
    _locationController = TextEditingController(text: widget.book.location ?? '');
    _category = widget.book.category;
    _condition = widget.book.condition;
    _listingType = widget.book.listingType;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final priceVal = double.tryParse(_priceController.text);
    final data = {
      'title': _titleController.text.trim(),
      'author': _authorController.text.trim(),
      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      'condition': _condition.name,
      'listing_type': _listingType.name,
      'price': (_listingType == ListingType.sell || _listingType == ListingType.both) ? priceVal : null,
      'category': _category,
      'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
    };
    final success = await context.read<AdminBookProvider>().updateBook(widget.book.id, data);
    setState(() => _isSaving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book listing updated successfully')));
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = context.read<AdminBookProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update book: ${error ?? 'Unknown error'}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<AdminCategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgCardDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary), onPressed: () => Navigator.of(context).pop()),
        title: Text('Edit Book Listing', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: AppSizes.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: GlassCard(
              padding: AppSizes.cardPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Book Title *'),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: _inputDecoration('Enter book title', isDark),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: AppSizes.s20),
                    _buildLabel('Author *'),
                    TextFormField(
                      controller: _authorController,
                      style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: _inputDecoration('Enter author name', isDark),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Author is required' : null,
                    ),
                    const SizedBox(height: AppSizes.s20),
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 500;
                      if (isWide) {
                        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: _buildCategoryField(categoryProvider, isDark)),
                          const SizedBox(width: AppSizes.s16),
                          Expanded(child: _buildConditionField(isDark)),
                        ]);
                      }
                      return Column(children: [_buildCategoryField(categoryProvider, isDark), const SizedBox(height: AppSizes.s16), _buildConditionField(isDark)]);
                    }),
                    const SizedBox(height: AppSizes.s20),
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 500;
                      if (isWide) {
                        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: _buildListingTypeField(isDark)),
                          const SizedBox(width: AppSizes.s16),
                          Expanded(child: _buildPriceField(isDark)),
                        ]);
                      }
                      return Column(children: [_buildListingTypeField(isDark), const SizedBox(height: AppSizes.s16), _buildPriceField(isDark)]);
                    }),
                    const SizedBox(height: AppSizes.s20),
                    _buildLabel('Location'),
                    TextFormField(
                      controller: _locationController,
                      style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: _inputDecoration('Enter physical location (optional)', isDark),
                    ),
                    const SizedBox(height: AppSizes.s20),
                    _buildLabel('Description'),
                    TextFormField(
                      controller: _descController, maxLines: 4,
                      style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: _inputDecoration('Enter book description or seller details...', isDark),
                    ),
                    const SizedBox(height: AppSizes.s32),
                    PremiumButton(
                      label: _isSaving ? 'Saving...' : 'Save Book Changes',
                      isLoading: _isSaving,
                      style: PremiumButtonStyle.gradient,
                      height: AppSizes.buttonLg,
                      onPressed: _isSaving ? null : () => _save(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
      filled: true,
      fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: AppSizes.s8), child: Text(text, style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)));

  Widget _buildDropdown<T>({required T value, required bool isDark, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: isDark ? AppColors.bgCardDark : Colors.white,
          style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          icon: Icon(Icons.arrow_drop_down_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          isExpanded: true,
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }

  Widget _buildCategoryField(AdminCategoryProvider categoryProvider, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel('Category'),
      _buildDropdown<String?>(
        value: _category,
        isDark: isDark,
        items: [const DropdownMenuItem<String?>(value: null, child: Text('None')), ...categoryProvider.categories.map((c) => DropdownMenuItem<String?>(value: c.name, child: Text(c.name)))],
        onChanged: (val) => setState(() => _category = val),
      ),
    ]);
  }

  Widget _buildConditionField(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel('Condition *'),
      _buildDropdown<BookCondition>(
        value: _condition,
        isDark: isDark,
        items: BookCondition.values.map((c) => DropdownMenuItem<BookCondition>(value: c, child: Text(_conditionLabel(c)))).toList(),
        onChanged: (val) { if (val != null) setState(() => _condition = val); },
      ),
    ]);
  }

  Widget _buildListingTypeField(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel('Listing Type *'),
      _buildDropdown<ListingType>(
        value: _listingType,
        isDark: isDark,
        items: ListingType.values.map((t) => DropdownMenuItem<ListingType>(value: t, child: Text(t.name.toUpperCase()))).toList(),
        onChanged: (val) { if (val != null) setState(() => _listingType = val); },
      ),
    ]);
  }

  Widget _buildPriceField(bool isDark) {
    final showPrice = _listingType == ListingType.sell || _listingType == ListingType.both;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel('Price (\$)'),
      TextFormField(
        controller: _priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: showPrice,
        style: GoogleFonts.poppins(color: showPrice ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary) : (isDark ? AppColors.textMutedDark : AppColors.textMuted), fontSize: 14, fontWeight: FontWeight.w500),
        decoration: _inputDecoration(showPrice ? 'Enter price' : 'Not applicable', isDark),
        validator: (val) {
          if (showPrice) { if (val == null || val.trim().isEmpty) return 'Price is required'; if (double.tryParse(val) == null) return 'Enter a valid price'; }
          return null;
        },
      ),
    ]);
  }

  String _conditionLabel(BookCondition c) => switch (c) { BookCondition.brandNew => 'Brand New', BookCondition.likeNew => 'Like New', BookCondition.good => 'Good', BookCondition.fair => 'Fair', BookCondition.poor => 'Poor' };
}
