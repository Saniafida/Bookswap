// lib/admin/screens/books/admin_book_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_book_provider.dart';
import '../../providers/admin_category_provider.dart';
import '../../../data/models/listing_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_button.dart';

class AdminBookEditScreen extends StatefulWidget {
  final ListingModel listing;
  const AdminBookEditScreen({super.key, required this.listing});

  @override
  State<AdminBookEditScreen> createState() => _AdminBookEditScreenState();
}

class _AdminBookEditScreenState extends State<AdminBookEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;
  String? _categoryId;
  late String _condition;
  late String _listingType;
  late String _status;
  bool _isSaving = false;

  static const List<String> _conditionOptions = ['brandNew', 'likeNew', 'good', 'fair', 'poor'];
  static const List<String> _listingTypeOptions = ['sell', 'exchange', 'donate', 'sell_exchange'];
  static const List<String> _statusOptions = ['active', 'sold', 'removed', 'expired'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing.title);
    _descController = TextEditingController(text: widget.listing.description ?? '');
    _priceController = TextEditingController(text: widget.listing.price?.toString() ?? '');
    _locationController = TextEditingController(text: widget.listing.location ?? '');
    _categoryId = widget.listing.categoryId;
    _condition = widget.listing.condition;
    _listingType = widget.listing.listingType;
    _status = widget.listing.status;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
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
      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      'condition': _condition,
      'listing_type': _listingType,
      'price': (_listingType == 'sell' || _listingType == 'sell_exchange') ? priceVal : null,
      'category_id': _categoryId,
      'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      'status': _status,
    };
    final success = await context.read<AdminBookProvider>().updateListing(widget.listing.id, data);
    setState(() => _isSaving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing updated successfully')));
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = context.read<AdminBookProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update listing: ${error ?? 'Unknown error'}')));
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
        title: Text('Edit Listing', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    _buildLabel('Listing Title *'),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: _inputDecoration('Enter listing title', isDark),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
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
                    _buildStatusField(isDark),
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
                      decoration: _inputDecoration('Enter listing description...', isDark),
                    ),
                    const SizedBox(height: AppSizes.s32),
                    PremiumButton(
                      label: _isSaving ? 'Saving...' : 'Save Listing Changes',
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
        value: _categoryId,
        isDark: isDark,
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('None')),
          ...categoryProvider.categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
        ],
        onChanged: (val) => setState(() => _categoryId = val),
      ),
    ]);
  }

  Widget _buildConditionField(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel('Condition *'),
      _buildDropdown<String>(
        value: _condition,
        isDark: isDark,
        items: _conditionOptions.map((c) => DropdownMenuItem<String>(value: c, child: Text(_conditionLabel(c)))).toList(),
        onChanged: (val) { if (val != null) setState(() => _condition = val); },
      ),
    ]);
  }

  Widget _buildListingTypeField(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel('Listing Type *'),
      _buildDropdown<String>(
        value: _listingType,
        isDark: isDark,
        items: _listingTypeOptions.map((t) => DropdownMenuItem<String>(value: t, child: Text(_listingTypeLabel(t)))).toList(),
        onChanged: (val) { if (val != null) setState(() => _listingType = val); },
      ),
    ]);
  }

  Widget _buildPriceField(bool isDark) {
    final showPrice = _listingType == 'sell' || _listingType == 'sell_exchange';
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

  Widget _buildStatusField(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel('Status *'),
      _buildDropdown<String>(
        value: _status,
        isDark: isDark,
        items: _statusOptions.map((s) => DropdownMenuItem<String>(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
        onChanged: (val) { if (val != null) setState(() => _status = val); },
      ),
    ]);
  }

  String _conditionLabel(String c) => switch (c) { 'brandNew' => 'Brand New', 'likeNew' => 'Like New', 'good' => 'Good', 'fair' => 'Fair', 'poor' => 'Poor', _ => c };
  String _listingTypeLabel(String t) => switch (t) { 'sell' => 'For Sale', 'exchange' => 'For Exchange', 'donate' => 'Free', 'sell_exchange' => 'Sell or Exchange', _ => t };
}
