import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/supabase_service.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_loading.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;
  const PostDetailsScreen({super.key, required this.postId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  PostModel? _post;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorited = false;
  int _carouselIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await SupabaseService.table('posts')
          .select('*, profiles(full_name, avatar_url)')
          .eq('id', widget.postId)
          .single();

      setState(() {
        _post = PostModel.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatCondition(BookCondition condition) {
    switch (condition) {
      case BookCondition.brandNew:
        return 'Brand New';
      case BookCondition.likeNew:
        return 'Like New';
      case BookCondition.good:
        return 'Good';
      case BookCondition.fair:
        return 'Fair';
      case BookCondition.poor:
        return 'Poor';
    }
  }

  String _formatListingType(ListingType type) {
    switch (type) {
      case ListingType.swap:
        return 'Swap';
      case ListingType.sell:
        return 'Sell';
      case ListingType.both:
        return 'Swap/Sell';
      case ListingType.donate:
        return 'Donate';
    }
  }

  Future<void> _handleMessageAction(BuildContext context, String currentUserId, String ownerId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chatId = await chatProvider.getOrCreateChat(currentUserId, ownerId);

      if (context.mounted) Navigator.pop(context);

      if (chatId != null && context.mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.chat,
          arguments: {'chatId': chatId},
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to initiate conversation.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorited = !_isFavorited;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorited ? 'Added to Saved Books' : 'Removed from Saved Books'),
        duration: const Duration(seconds: 2),
        backgroundColor: _isFavorited ? AppColors.success : AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    Widget bodyWidget;

    if (_isLoading) {
      bodyWidget = const Center(
        key: ValueKey('loading'),
        child: PremiumLoading(size: 32, message: 'Loading book details...'),
      );
    } else if (_errorMessage != null || _post == null) {
      bodyWidget = Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: AppSizes.pagePaddingLarge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                ),
                child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
              ),
              const SizedBox(height: AppSizes.s20),
              Text(
                'Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.s8),
              Text(
                _errorMessage ?? 'Book listing not found',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.s24),
              PremiumButton(
                label: 'Try Again',
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                onPressed: _loadPostDetails,
                width: 160,
              ),
            ],
          ),
        ),
      );
    } else {
      final post = _post!;
      final isOwner = currentUserId == post.userId;

      List<Widget> carouselSlides = [];

      if (post.imageUrls.isNotEmpty) {
        for (final url in post.imageUrls) {
          carouselSlides.add(
            Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => _buildCoverPlaceholder(theme),
                ),
              ],
            ),
          );
        }
      } else if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
        carouselSlides.add(
          Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => _buildCoverPlaceholder(theme),
              ),
            ],
          ),
        );
      } else {
        carouselSlides.add(_buildCoverPlaceholder(theme));
      }

      final carouselWidget = SizedBox(
        height: 420,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: carouselSlides.length,
              onPageChanged: (index) {
                setState(() {
                  _carouselIndex = index;
                });
              },
              itemBuilder: (context, index) => carouselSlides[index],
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  carouselSlides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _carouselIndex == index ? 24 : 6,
                    decoration: BoxDecoration(
                      color: _carouselIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Text(
                  '${_carouselIndex + 1} / ${carouselSlides.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      bodyWidget = Stack(
        key: const ValueKey('loaded'),
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 420),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: AppSizes.radiusXl,
                    margin: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.s20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getListingTypeColor(post.listingType).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                post.listingType == ListingType.swap
                                                    ? Icons.swap_horiz_rounded
                                                    : post.listingType == ListingType.donate
                                                        ? Icons.volunteer_activism_rounded
                                                        : Icons.sell_rounded,
                                                size: 14,
                                                color: _getListingTypeColor(post.listingType),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatListingType(post.listingType),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getListingTypeColor(post.listingType),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: AppSizes.s12),
                                        Text(
                                          post.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: AppSizes.s4),
                                        Text(
                                          'by ${post.author}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.s16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      post.listingType == ListingType.swap
                                          ? 'Swap'
                                          : post.listingType == ListingType.donate
                                              ? 'Free'
                                              : post.price != null
                                                  ? '\$${post.price!.toStringAsFixed(0)}'
                                                  : 'Free',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.s20),
                              Wrap(
                                spacing: AppSizes.s8,
                                runSpacing: AppSizes.s8,
                                children: [
                                  _buildMetricChip(
                                    icon: Icons.folder_open_rounded,
                                    label: post.category ?? 'General',
                                    theme: theme,
                                    isDark: isDark,
                                  ),
                                  _buildMetricChip(
                                    icon: Icons.star_border_rounded,
                                    label: _formatCondition(post.condition),
                                    theme: theme,
                                    isDark: isDark,
                                  ),
                                  if (post.location != null)
                                    _buildMetricChip(
                                      icon: Icons.location_on_outlined,
                                      label: post.location!,
                                      theme: theme,
                                      isDark: isDark,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.5),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.s20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.s10),
                                  Text(
                                    'About this book',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.s12),
                              Text(
                                post.description ?? 'No details or descriptions were provided for this book.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.7,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
                  child: GlassCard(
                    borderRadius: AppSizes.radiusLg,
                    padding: const EdgeInsets.all(AppSizes.s16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.profile,
                          arguments: {'userId': post.userId},
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: CircleAvatar(
                              radius: 23,
                              backgroundColor: Colors.transparent,
                              backgroundImage: post.ownerAvatarUrl != null
                                  ? NetworkImage(post.ownerAvatarUrl!)
                                  : null,
                              child: post.ownerAvatarUrl == null
                                  ? Text(
                                      ((post.ownerName ?? '').isNotEmpty ? post.ownerName![0] : 'U').toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSizes.s14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.ownerName ?? 'Unknown User',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Listing Owner',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: carouselWidget,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.s20,
                    AppSizes.s16,
                    AppSizes.s20,
                    MediaQuery.of(context).padding.bottom + AppSizes.s16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.bgDark.withValues(alpha: 0.82)
                        : Colors.white.withValues(alpha: 0.82),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!isOwner)
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                              child: Icon(
                                _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                key: ValueKey<bool>(_isFavorited),
                                color: _isFavorited ? AppColors.error : AppColors.primary,
                                size: AppSizes.iconMd,
                              ),
                            ),
                            onPressed: _toggleFavorite,
                          ),
                        ),
                      if (!isOwner) const SizedBox(width: AppSizes.s12),
                      Expanded(
                        child: PremiumButton(
                          label: isOwner ? 'Manage Listing' : 'Message Owner',
                          icon: Icon(
                            isOwner ? Icons.tune_rounded : Icons.forum_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          style: isOwner ? PremiumButtonStyle.secondary : PremiumButtonStyle.gradient,
                          height: AppSizes.buttonLg,
                          onPressed: () {
                            if (isOwner) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("This is your own listing."),
                                ),
                              );
                            } else if (currentUserId != null) {
                              _handleMessageAction(context, currentUserId, post.userId);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please sign in to message book owners.'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSizes.s12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 40,
                height: 40,
                color: Colors.black.withValues(alpha: 0.25),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ),
        actions: [
          if (_post != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.s12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 40,
                    height: 40,
                    color: Colors.black.withValues(alpha: 0.25),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey<bool>(_isFavorited),
                          color: _isFavorited ? AppColors.error : Colors.white,
                          size: AppSizes.iconSm,
                        ),
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: bodyWidget,
      ),
    );
  }

  Widget _buildCoverPlaceholder(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: Icon(
              Icons.book_rounded,
              size: 36,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          Text(
            'No cover photo provided',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12, vertical: AppSizes.s8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: AppSizes.s6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getListingTypeColor(ListingType type) {
    switch (type) {
      case ListingType.swap:
        return Colors.blue;
      case ListingType.sell:
        return const Color(0xFF10B981);
      case ListingType.both:
        return Colors.purple;
      case ListingType.donate:
        return const Color(0xFFE11D48);
    }
  }
}
