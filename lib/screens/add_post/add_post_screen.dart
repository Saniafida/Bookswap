import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_textfield.dart';
import '../bottom_nav/bottom_nav_screen.dart';

class _Option<T> {
  final T value;
  final String label;
  final IconData icon;
  final Color color;
  const _Option(this.value, this.label, this.icon, this.color);
}

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  List<XFile> _selectedImages = [];
  String? _selectedCategory;
  BookCondition _selectedCondition = BookCondition.good;
  ListingType _selectedListingType = ListingType.swap;

  final ScrollController _scrollController = ScrollController();
  double _progress = 0.0;

  final ImagePicker _picker = ImagePicker();

  static const int _maxImages = 5;

  static final List<_Option<BookCondition>> _conditions = [
    _Option(BookCondition.brandNew, 'Brand New', Icons.star_rounded, const Color(0xFF059669)),
    _Option(BookCondition.likeNew, 'Like New', Icons.star_half_rounded, const Color(0xFF0EA5E9)),
    _Option(BookCondition.good, 'Good', Icons.thumb_up_rounded, const Color(0xFF6366F1)),
    _Option(BookCondition.fair, 'Fair', Icons.thumbs_up_down_rounded, const Color(0xFFF59E0B)),
    _Option(BookCondition.poor, 'Poor', Icons.thumb_down_rounded, const Color(0xFFEF4444)),
  ];

  static final List<_Option<ListingType>> _listingTypes = [
    _Option(ListingType.swap, 'Exchange', Icons.swap_horiz_rounded, const Color(0xFF2563EB)),
    _Option(ListingType.sell, 'Sell', Icons.sell_rounded, const Color(0xFF059669)),
    _Option(ListingType.both, 'Both', Icons.compare_arrows_rounded, const Color(0xFF7C3AED)),
    _Option(ListingType.donate, 'Donate', Icons.volunteer_activism_rounded, const Color(0xFFE11D48)),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cp = context.read<CategoryProvider>();
      if (cp.status == CategoryStatus.initial) {
        cp.fetchCategories();
        cp.subscribeToCategories();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final p = (_scrollController.offset / max).clamp(0.0, 1.0);
    if ((p - _progress).abs() > 0.005) setState(() => _progress = p);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final remaining = _maxImages - _selectedImages.length;
      if (remaining <= 0) return;
      final picked = await _picker.pickMultiImage(
        imageQuality: 82,
        maxWidth: 1200,
      );
      if (picked.isNotEmpty) {
        setState(() {
          _selectedImages = [
            ..._selectedImages,
            ...picked,
          ].take(_maxImages).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Could not open gallery: $e', isError: true);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1200,
      );
      if (img != null) {
        setState(() {
          _selectedImages = [..._selectedImages, img].take(_maxImages).toList();
        });
      }
    } catch (e) {
      if (mounted) _showSnack('Could not open camera.', isError: true);
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  void _reorderImages(int oldIdx, int newIdx) {
    setState(() {
      if (newIdx > oldIdx) newIdx -= 1;
      final item = _selectedImages.removeAt(oldIdx);
      _selectedImages.insert(newIdx, item);
    });
  }

  void _clearForm() {
    _titleController.clear();
    _authorController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _locationController.clear();
    setState(() {
      _selectedImages = [];
      _selectedCategory = null;
      _selectedCondition = BookCondition.good;
      _selectedListingType = ListingType.swap;
    });
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    if (_selectedImages.isEmpty) {
      _showSnack('Please add at least one photo.', isError: true);
      return;
    }
    if (_selectedCategory == null) {
      _showSnack('Please select a category.', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) {
      _showSnack('You must be signed in to post.', isError: true);
      return;
    }

    final price = (_selectedListingType == ListingType.sell ||
            _selectedListingType == ListingType.both)
        ? double.tryParse(_priceController.text.trim())
        : null;

    final post = PostModel(
      id: '',
      userId: userId,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      imageUrl: null,
      condition: _selectedCondition,
      listingType: _selectedListingType,
      price: price,
      category: _selectedCategory,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      isAvailable: true,
      createdAt: DateTime.now(),
    );

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final success = await postProvider.createPost(
      post,
      imageFiles: _selectedImages,
    );

    if (!mounted) return;

    if (success) {
      _showSnack('Your listing is live!', isError: false);
      _clearForm();
      final nav = context.findAncestorStateOfType<BottomNavScreenState>();
      if (nav != null) {
        nav.selectTab(0);
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      _showSnack(
        postProvider.errorMessage ?? 'Failed to publish. Try again.',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.select<PostProvider, bool>((p) => p.isLoading);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _buildAppBar(theme, isDark, isLoading),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: isLoading,
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _SectionHeader(
                          title: 'Photos',
                          subtitle: 'First photo is the cover \u00b7 Drag to reorder \u00b7 Max $_maxImages',
                        ),
                        SizedBox(height: AppSizes.s12),
                        _buildImagePicker(theme, isDark),
                        SizedBox(height: AppSizes.s28),

                        GlassCard(
                          padding: AppSizes.cardPadding,
                          child: Column(
                            children: [
                              PremiumTextField(
                                controller: _titleController,
                                label: 'Book Title',
                                hint: 'Enter the title of the book',
                                prefixIcon: Icon(Icons.menu_book_rounded, size: AppSizes.iconSm, color: AppColors.primary),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
                              ),
                              SizedBox(height: AppSizes.s16),
                              PremiumTextField(
                                controller: _authorController,
                                label: 'Author',
                                hint: 'Who wrote this book?',
                                prefixIcon: Icon(Icons.person_rounded, size: AppSizes.iconSm, color: AppColors.primary),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
                              ),
                              SizedBox(height: AppSizes.s16),
                              PremiumTextField(
                                controller: _descriptionController,
                                label: 'Description',
                                hint: 'Describe the book, its condition, why you\u2019re listing it\u2026',
                                prefixIcon: Icon(Icons.notes_rounded, size: AppSizes.iconSm, color: AppColors.primary),
                                maxLines: 4,
                              ),
                              SizedBox(height: AppSizes.s16),
                              PremiumTextField(
                                controller: _locationController,
                                label: 'Pickup Location',
                                hint: 'e.g. Downtown, Lahore',
                                prefixIcon: Icon(Icons.location_on_rounded, size: AppSizes.iconSm, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSizes.s28),

                        _SectionHeader(title: 'Category'),
                        SizedBox(height: AppSizes.s12),
                        _buildCategoryGrid(theme, isDark),
                        SizedBox(height: AppSizes.s28),

                        _SectionHeader(title: 'Condition'),
                        SizedBox(height: AppSizes.s12),
                        _buildConditionSelector(theme, isDark),
                        SizedBox(height: AppSizes.s28),

                        _SectionHeader(title: 'Listing Type'),
                        SizedBox(height: AppSizes.s12),
                        _buildListingTypeSelector(theme, isDark),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: (_selectedListingType == ListingType.sell ||
                                  _selectedListingType == ListingType.both)
                              ? Padding(
                                  padding: EdgeInsets.only(top: AppSizes.s16),
                                  child: GlassCard(
                                    padding: AppSizes.cardPadding,
                                    child: PremiumTextField(
                                      controller: _priceController,
                                      label: 'Price (USD)',
                                      hint: '0.00',
                                      prefixIcon: Icon(Icons.attach_money_rounded, size: AppSizes.iconSm, color: AppColors.primary),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                      ],
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Enter a price';
                                        final n = double.tryParse(v.trim());
                                        if (n == null || n <= 0) return 'Enter a valid price > 0';
                                        return null;
                                      },
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildPublishBar(theme, isLoading),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark, bool isLoading) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 3),
      child: Column(
        children: [
          AppBar(
            title: const Text(
              'List a Book',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (_selectedImages.isNotEmpty || _titleController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.restart_alt_rounded),
                  tooltip: 'Reset',
                  onPressed: isLoading ? null : _clearForm,
                ),
              const SizedBox(width: 4),
            ],
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progress),
            duration: const Duration(milliseconds: 200),
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 3,
              backgroundColor: Colors.transparent,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme, bool isDark) {
    if (_selectedImages.isEmpty) {
      return _ImagePickerEmpty(
        onGallery: _pickImages,
        onCamera: _pickFromCamera,
        theme: theme,
        isDark: isDark,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 144,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            onReorder: _reorderImages,
            itemCount: _selectedImages.length +
                (_selectedImages.length < _maxImages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return _AddMoreTile(
                  key: const ValueKey('add_more'),
                  onGallery: _pickImages,
                  onCamera: _pickFromCamera,
                  theme: theme,
                  isDark: isDark,
                );
              }

              final img = _selectedImages[index];
              final isCover = index == 0;

              return ReorderableDragStartListener(
                key: ValueKey(img.path),
                index: index,
                child: _ImageTile(
                  xfile: img,
                  isCover: isCover,
                  onRemove: () => _removeImage(index),
                  theme: theme,
                ),
              );
            },
          ),
        ),
        if (_selectedImages.length < _maxImages)
          Padding(
            padding: EdgeInsets.only(top: AppSizes.s8),
            child: Text(
              '${_selectedImages.length}/$_maxImages photos added',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white38 : AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryGrid(ThemeData theme, bool isDark) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categoryNames;

    if (categoryProvider.isLoading && categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No categories available',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white38 : AppColors.textMuted,
          ),
        ),
      );
    }

    return GlassCard(
      padding: AppSizes.cardPaddingCompact,
      child: Wrap(
        spacing: AppSizes.s8,
        runSpacing: AppSizes.s8,
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = isSelected ? null : cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.bgSurfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.border),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConditionSelector(ThemeData theme, bool isDark) {
    return GlassCard(
      padding: AppSizes.cardPaddingCompact,
      child: Row(
        children: _conditions.map((opt) {
          final isSelected = _selectedCondition == opt.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCondition = opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? opt.color.withValues(alpha: 0.12)
                      : (isDark ? AppColors.bgSurfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? opt.color
                        : (isDark ? Colors.white.withValues(alpha: 0.07) : AppColors.border),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.icon, size: 20, color: isSelected ? opt.color : (isDark ? Colors.white38 : AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      opt.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? opt.color : (isDark ? Colors.white54 : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListingTypeSelector(ThemeData theme, bool isDark) {
    return GlassCard(
      padding: AppSizes.cardPaddingCompact,
      child: Row(
        children: _listingTypes.map((opt) {
          final isSelected = _selectedListingType == opt.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedListingType = opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? opt.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? opt.color
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.border),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: opt.color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.icon, size: 22, color: isSelected ? Colors.white : (isDark ? Colors.white54 : AppColors.textMuted)),
                    const SizedBox(height: 5),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPublishBar(ThemeData theme, bool isLoading) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.border,
            ),
          ),
        ),
        child: PremiumButton(
          label: 'Publish Listing',
          style: PremiumButtonStyle.gradient,
          isLoading: isLoading,
          onPressed: isLoading ? null : _submitForm,
          icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
          height: AppSizes.buttonXl,
          borderRadius: AppSizes.radiusMd,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white38 : AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _ImagePickerEmpty extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final ThemeData theme;
  final bool isDark;

  const _ImagePickerEmpty({
    required this.onGallery,
    required this.onCamera,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 144,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Row(
            children: [
              Expanded(
                child: _PickerActionTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  subtitle: 'Pick multiple',
                  onTap: onGallery,
                  theme: theme,
                  isDark: isDark,
                  showRightBorder: true,
                ),
              ),
              Expanded(
                child: _PickerActionTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  subtitle: 'Take a photo',
                  onTap: onCamera,
                  theme: theme,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;
  final bool showRightBorder;

  const _PickerActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.theme,
    required this.isDark,
    this.showRightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showRightBorder
              ? Border(right: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white38 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final XFile xfile;
  final bool isCover;
  final VoidCallback onRemove;
  final ThemeData theme;

  const _ImageTile({
    required this.xfile,
    required this.isCover,
    required this.onRemove,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: kIsWeb
                  ? Image.network(xfile.path, fit: BoxFit.cover)
                  : Image.file(File(xfile.path), fit: BoxFit.cover),
            ),
          ),
          if (isCover)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppSizes.radiusMd),
                    bottomRight: Radius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                    SizedBox(width: 3),
                    Text(
                      'COVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.drag_handle_rounded, size: 14, color: Colors.white70),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMoreTile extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final ThemeData theme;
  final bool isDark;

  const _AddMoreTile({
    super.key,
    required this.onGallery,
    required this.onCamera,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? AppColors.bgCardDark : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  onGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  onCamera();
                },
              ),
            ],
          ),
        ),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_rounded, size: 26, color: AppColors.primary),
                const SizedBox(height: 5),
                Text(
                  'Add Photo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
