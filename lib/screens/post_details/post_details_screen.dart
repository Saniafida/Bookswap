import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_dialogs.dart';
import '../../widgets/premium_loading.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  ListingModel? _listing;
  bool _isLoading = true;
  String? _errorMessage;
  int _carouselIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadListingDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadListingDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final listingProvider = Provider.of<ListingProvider>(context, listen: false);
      final listing = await listingProvider.fetchListing(widget.listingId);

      if (!mounted) return;

      if (listing != null) {
        setState(() {
          _listing = listing;
          _isLoading = false;
        });

        listingProvider.incrementViewCount(widget.listingId);

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.id;
        if (userId != null) {
          final favProvider = Provider.of<FavoriteProvider>(context, listen: false);
          if (favProvider.favoriteIds.isEmpty) {
            favProvider.fetchFavorites(userId);
          }
        }
      } else {
        setState(() {
          _errorMessage = listingProvider.errorMessage ?? 'Listing not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Color _getListingTypeColor(String type) {
    return switch (type) {
      'exchange' => const Color(0xFF3B82F6),
      'sell' => const Color(0xFF10B981),
      'sellExchange' => const Color(0xFF7C3AED),
      'sell_exchange' => const Color(0xFF7C3AED),
      'donate' => const Color(0xFFE11D48),
      _ => AppColors.primary,
    };
  }

  String _formatPrice(double? price, String type) {
    if (price != null) {
      final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      final String Function(Match) mathFunc = (Match match) => '${match[1]},';
      final String formatted = price.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
      return 'PKR $formatted';
    }
    return type == 'donate' ? 'Free' : '';
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
          arguments: {
            'chatId': chatId,
            'participantName': _listing?.ownerName,
            'participantAvatarUrl': _listing?.ownerAvatarUrl,
          },
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

  Future<void> _handleToggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save items.')),
      );
      return;
    }

    final favProvider = Provider.of<FavoriteProvider>(context, listen: false);
    final isFav = await favProvider.toggleFavorite(userId, widget.listingId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFav ? 'Added to Favorites' : 'Removed from Favorites'),
        duration: const Duration(seconds: 2),
        backgroundColor: isFav ? AppColors.success : AppColors.textSecondary,
      ),
    );
  }

  void _handleShare() {
    final listing = _listing;
    if (listing == null) return;
    Clipboard.setData(ClipboardData(
      text: 'Check out "${listing.title}" on Swaply! Price: ${_formatPrice(listing.price, listing.listingType)}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDelete() async {
    await PremiumDialog.confirm(
      context,
      title: 'Delete Listing',
      message: 'Are you sure you want to delete this listing? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
      onConfirm: () async {
        final listingProvider = Provider.of<ListingProvider>(context, listen: false);
        final success = await listingProvider.deleteListing(widget.listingId);
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing deleted.')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(listingProvider.errorMessage ?? 'Failed to delete.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
    final isFavorited = widget.listingId.isNotEmpty
        ? favoriteProvider.isFavorited(widget.listingId)
        : false;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: PremiumLoading(size: 32, message: 'Loading listing details...'),
        ),
      );
    }

    if (_errorMessage != null || _listing == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
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
                  _errorMessage ?? 'Listing not found',
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
                  onPressed: _loadListingDetails,
                  width: 160,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final listing = _listing!;
    final isOwner = currentUserId == listing.userId;
    final imageUrls = listing.images.map((img) => img.url).toList();
    final hasImages = imageUrls.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Image slider app bar
              SliverAppBar(
                expandedHeight: 380,
                backgroundColor: AppColors.bgLight,
                elevation: 0,
                scrolledUnderElevation: 0,
                pinned: true,
                stretch: true,
                leadingWidth: 56,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
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
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: 40,
                          height: 40,
                          color: Colors.black.withValues(alpha: 0.25),
                          child: IconButton(
                            icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                            onPressed: _handleShare,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: hasImages ? imageUrls.length : 1,
                        onPageChanged: (index) {
                          setState(() {
                            _carouselIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          if (!hasImages) {
                            return _buildCoverPlaceholder(theme);
                          }
                          return Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildCoverPlaceholder(theme),
                          );
                        },
                      ),
                      // Soft gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Dots Indicator
                      if (hasImages && imageUrls.length > 1)
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imageUrls.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 6,
                                width: _carouselIndex == index ? 20 : 6,
                                decoration: BoxDecoration(
                                  color: _carouselIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Slide Index Badge
                      if (hasImages)
                        Positioned(
                          bottom: 20,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${_carouselIndex + 1} / ${imageUrls.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Scrollable body details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 130), // Extra bottom padding for floating bar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag category rows
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getListingTypeColor(listing.listingType).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  listing.listingTypeIcon,
                                  size: 13,
                                  color: _getListingTypeColor(listing.listingType),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  listing.listingTypeLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: _getListingTypeColor(listing.listingType),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (listing.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                listing.categoryName!,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Title & Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (listing.price != null || listing.listingType == 'donate')
                            Text(
                              _formatPrice(listing.price, listing.listingType),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryLight,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Metric Items Grid horizontal row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildMetricItem(
                              icon: Icons.star_rounded,
                              title: 'Condition',
                              value: listing.conditionLabel,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _buildMetricItem(
                              icon: Icons.remove_red_eye_rounded,
                              title: 'Views',
                              value: '${listing.viewCount} views',
                              isDark: isDark,
                            ),
                            if (listing.location != null) ...[
                              const SizedBox(width: 10),
                              _buildMetricItem(
                                icon: Icons.location_on_rounded,
                                title: 'Location',
                                value: listing.location!,
                                isDark: isDark,
                              ),
                            ],
                            if (listing.price != null && listing.isNegotiable) ...[
                              const SizedBox(width: 10),
                              _buildMetricItem(
                                icon: Icons.handshake_rounded,
                                title: 'Offer Type',
                                value: 'Negotiable',
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Divider line
                      Container(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),
                      // Product Description
                      Text(
                        'Product Description',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        listing.description ?? 'No description provided.',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          height: 1.7,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Owner Card
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.profile,
                            arguments: {'userId': listing.userId},
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                backgroundImage: listing.ownerAvatarUrl != null
                                    ? NetworkImage(listing.ownerAvatarUrl!)
                                    : null,
                                child: listing.ownerAvatarUrl == null
                                    ? Text(
                                        ((listing.ownerName ?? '').isNotEmpty ? listing.ownerName![0] : 'U').toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing.ownerName ?? 'Seller Partner',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_formatTimeAgo(listing.createdAt)} \u00b7 Listing Owner',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating premium Bottom Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom > 0 ? 16 : 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Favorite button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorited ? AppColors.error : AppColors.primary,
                            size: 20,
                          ),
                          onPressed: _handleToggleFavorite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Share button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.share_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: _handleShare,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action button (message / delete)
                      Expanded(
                        child: isOwner
                            ? PremiumButton(
                                label: 'Delete',
                                icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.white),
                                style: PremiumButtonStyle.primary,
                                color: AppColors.error,
                                height: 48,
                                onPressed: _handleDelete,
                              )
                            : PremiumButton(
                                label: currentUserId != null ? 'Message' : 'Sign in to Message',
                                icon: const Icon(
                                  Icons.forum_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                style: PremiumButtonStyle.gradient,
                                height: 48,
                                onPressed: () {
                                  if (currentUserId != null) {
                                    _handleMessageAction(context, currentUserId, listing.userId);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please sign in to message the owner.'),
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
              Icons.image_rounded,
              size: 36,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          Text(
            'No images provided',
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

  Widget _buildMetricItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E9), // Light cream background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEDD9C8).withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
