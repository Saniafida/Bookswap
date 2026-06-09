// lib/admin/screens/books/admin_add_book_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_book_provider.dart';
import '../../providers/admin_category_provider.dart';
import 'package:bookswap/models/post_model.dart';
import 'package:bookswap/core/services/storage_service.dart';
import 'package:bookswap/core/services/supabase_service.dart';
import '../../widgets/admin_section_header.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_button.dart';
import '../../../widgets/premium_textfield.dart';

class AdminAddBookScreen extends StatefulWidget {
  const AdminAddBookScreen({super.key});

  @override
  State<AdminAddBookScreen> createState() => _AdminAddBookScreenState();
}

class _AdminAddBookScreenState extends State<AdminAddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  String? _category;
  BookCondition _condition = BookCondition.good;
  ListingType _listingType = ListingType.swap;
  bool _isSaving = false;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() { _imageBytes = bytes; _imageName = picked.name; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      String? imageUrl;
      if (_imageBytes != null && _imageName != null) {
        final userId = SupabaseService.currentUser?.id ?? 'admin';
        final urls = await StorageService.uploadMultipleImages([(bytes: _imageBytes!, name: _imageName!)], userId);
        if (urls.isNotEmpty) imageUrl = urls.first;
      }
      final priceVal = double.tryParse(_priceController.text);
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');
      final data = {
        'user_id': userId,
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'condition': _condition.name,
        'listing_type': _listingType.name,
        'price': (_listingType == ListingType.sell || _listingType == ListingType.both) ? priceVal : null,
        'category': _category,
        'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'is_available': true,
        'is_featured': false,
        if (imageUrl != null) 'image_url': imageUrl,
      };
      final success = await context.read<AdminBookProvider>().createBook(data);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book listing created successfully!'), backgroundColor: AppColors.success));
        Navigator.of(context).pop();
      } else if (mounted) {
        final error = context.read<AdminBookProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create book: ${error ?? 'Unknown error'}'), backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<AdminCategoryProvider>();
    final showPrice = _listingType == ListingType.sell || _listingType == ListingType.both;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgCardDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary), onPressed: () => Navigator.of(context).pop()),
        title: Text('Add Book Listing', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.s12),
            child: TextButton(
              onPressed: _isSaving ? null : () => _save(context),
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : Text('Save', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSizes.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Cover Image'),
                  const SizedBox(height: AppSizes.s10),
                  GestureDetector(
                    onTap: _isPickingImage ? null : _pickImage,
                    child: Container(
                      width: double.infinity, height: 180,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(color: _imageBytes != null ? AppColors.primary.withValues(alpha: 0.4) : (isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)), width: _imageBytes != null ? 2 : 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _isPickingImage
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : _imageBytes != null
                              ? Stack(fit: StackFit.expand, children: [
                                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                                  Positioned(bottom: 10, right: 10, child: GestureDetector(
                                    onTap: () => setState(() { _imageBytes = null; _imageName = null; }),
                                    child: Container(padding: const EdgeInsets.all(AppSizes.s6), decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppSizes.radiusXs)), child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16)),
                                  )),
                                ])
                              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 36, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
                                  const SizedBox(height: AppSizes.s8),
                                  Text('Tap to select cover image', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: AppSizes.s4),
                                  Text('Optional · JPG, PNG', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 11)),
                                ]),
                    ),
                  ),
                  const SizedBox(height: AppSizes.s24),
                  GlassCard(
                    padding: AppSizes.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Book Title *'),
                        TextFormField(
                          controller: _titleController,
                          style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Enter book title',
                            hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
                            filled: true,
                            fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: AppSizes.s20),
                        _buildLabel('Author *'),
                        TextFormField(
                          controller: _authorController,
                          style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Enter author name',
                            hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
                            filled: true,
                            fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Author is required' : null,
                        ),
                        const SizedBox(height: AppSizes.s20),
                        LayoutBuilder(builder: (ctx, constraints) {
                          final isNarrow = constraints.maxWidth < 450;
                          final categoryField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildLabel('Category'),
                            _buildDropdown<String?>(
                              value: _category,
                              hint: 'Select category',
                              isDark: isDark,
                              items: [const DropdownMenuItem<String?>(value: null, child: Text('None')), ...categoryProvider.categories.map((c) => DropdownMenuItem<String?>(value: c.name, child: Text(c.name)))],
                              onChanged: (val) => setState(() => _category = val),
                            ),
                          ]);
                          final conditionField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildLabel('Condition *'),
                            _buildDropdown<BookCondition>(
                              value: _condition,
                              isDark: isDark,
                              items: BookCondition.values.map((c) => DropdownMenuItem<BookCondition>(value: c, child: Text(_conditionLabel(c)))).toList(),
                              onChanged: (val) { if (val != null) setState(() => _condition = val); },
                            ),
                          ]);
                          return isNarrow
                              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [categoryField, const SizedBox(height: AppSizes.s16), conditionField])
                              : Row(children: [Expanded(child: categoryField), const SizedBox(width: AppSizes.s16), Expanded(child: conditionField)]);
                        }),
                        const SizedBox(height: AppSizes.s20),
                        LayoutBuilder(builder: (ctx, constraints) {
                          final isNarrow = constraints.maxWidth < 450;
                          final listingWidget = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildLabel('Listing Type *'),
                            _buildDropdown<ListingType>(
                              value: _listingType,
                              isDark: isDark,
                              items: ListingType.values.map((t) => DropdownMenuItem<ListingType>(value: t, child: Text(t.name.toUpperCase()))).toList(),
                              onChanged: (val) { if (val != null) setState(() => _listingType = val); },
                            ),
                          ]);
                          final priceWidget = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildLabel('Price (\$)'),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: showPrice,
                              style: GoogleFonts.poppins(color: showPrice ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary) : (isDark ? AppColors.textMutedDark : AppColors.textMuted), fontSize: 14, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: showPrice ? 'Enter price' : 'Not applicable',
                                hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
                                filled: true,
                                fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
                              ),
                              validator: (val) {
                                if (showPrice) { if (val == null || val.trim().isEmpty) return 'Price is required'; if (double.tryParse(val) == null) return 'Enter a valid price'; }
                                return null;
                              },
                            ),
                          ]);
                          return isNarrow
                              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [listingWidget, const SizedBox(height: AppSizes.s16), priceWidget])
                              : Row(children: [Expanded(child: listingWidget), const SizedBox(width: AppSizes.s16), Expanded(child: priceWidget)]);
                        }),
                        const SizedBox(height: AppSizes.s20),
                        _buildLabel('Location'),
                        TextFormField(
                          controller: _locationController,
                          style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Enter physical location (optional)',
                            hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
                            filled: true,
                            fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
                          ),
                        ),
                        const SizedBox(height: AppSizes.s20),
                        _buildLabel('Description'),
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Enter book description or details...',
                            hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
                            filled: true,
                            fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.s28),
                  PremiumButton(
                    label: _isSaving ? 'Creating...' : 'Create Book Listing',
                    icon: _isSaving ? null : const Icon(Icons.add_circle_outline_rounded, size: 18),
                    isLoading: _isSaving,
                    style: PremiumButtonStyle.gradient,
                    height: AppSizes.buttonLg,
                    onPressed: _isSaving ? null : () => _save(context),
                  ),
                  const SizedBox(height: AppSizes.s32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({required T value, String? hint, required bool isDark, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
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
          hint: hint != null ? Text(hint, style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14)) : null,
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

  Widget _buildSectionTitle(String title) => Text(title, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w700));
  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: AppSizes.s8), child: Text(text, style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)));
  String _conditionLabel(BookCondition c) => switch (c) { BookCondition.brandNew => 'Brand New', BookCondition.likeNew => 'Like New', BookCondition.good => 'Good', BookCondition.fair => 'Fair', BookCondition.poor => 'Poor' };
}
