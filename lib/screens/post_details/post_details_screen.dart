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
import '../../widgets/glass_card.dart';
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
      text: 'Check out "${listing.title}" on Swaply! Price: ${listing.priceLabel}',
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

    Widget bodyWidget;

    if (_isLoading) {
      bodyWidget = const Center(
        key: ValueKey('loading'),
        child: PremiumLoading(size: 32, message: 'Loading listing details...'),
      );
    } else if (_errorMessage != null || _listing == null) {
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
      );
    } else {
      final listing = _listing!;
      final isOwner = currentUserId == listing.userId;

      final imageUrls = listing.images.map((img) => img.url).toList();
      final hasImages = imageUrls.isNotEmpty;

      List<Widget> carouselSlides = [];
      if (hasImages) {
        for (final url in imageUrls) {
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
                                            color: _getListingTypeColor(listing.listingType).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                listing.listingTypeIcon,
                                                size: 14,
                                                color: _getListingTypeColor(listing.listingType),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                listing.listingTypeLabel,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getListingTypeColor(listing.listingType),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: AppSizes.s12),
                                        Text(
                                          listing.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.s16),
                                  if (listing.price != null || listing.listingType == 'donate')
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
                                        listing.priceLabel,
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
                                  if (listing.categoryName != null)
                                    _buildMetricChip(
                                      icon: Icons.folder_open_rounded,
                                      label: listing.categoryName!,
                                      theme: theme,
                                      isDark: isDark,
                                    ),
                                  _buildMetricChip(
                                    icon: Icons.star_border_rounded,
                                    label: listing.conditionLabel,
                                    theme: theme,
                                    isDark: isDark,
                                  ),
                                  if (listing.location != null)
                                    _buildMetricChip(
                                      icon: Icons.location_on_outlined,
                                      label: listing.location!,
                                      theme: theme,
                                      isDark: isDark,
                                    ),
                                  if (listing.price != null && listing.isNegotiable)
                                    _buildMetricChip(
                                      icon: Icons.handshake_rounded,
                                      label: 'Negotiable',
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
                                  Flexible(
                                    child: Text(
                                      'Description',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.s12),
                              Text(
                                listing.description ?? 'No description provided.',
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
                          arguments: {'userId': listing.userId},
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
                              backgroundImage: listing.ownerAvatarUrl != null
                                  ? NetworkImage(listing.ownerAvatarUrl!)
                                  : null,
                              child: listing.ownerAvatarUrl == null
                                  ? Text(
                                      ((listing.ownerName ?? '').isNotEmpty ? listing.ownerName![0] : 'U').toUpperCase(),
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
                                  listing.ownerName ?? 'Unknown User',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
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
                    color: Colors.white.withValues(alpha: 0.92),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorited ? AppColors.error : AppColors.primary,
                            size: AppSizes.iconMd,
                          ),
                          onPressed: _handleToggleFavorite,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s12),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.share_rounded,
                            color: AppColors.primary,
                            size: AppSizes.iconMd,
                          ),
                          onPressed: _handleShare,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s12),
                      Expanded(
                        child: isOwner
                            ? Row(
                                children: [
                                  Expanded(
                                    child: PremiumButton(
                                      label: 'Delete',
                                      icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.white),
                                      style: PremiumButtonStyle.primary,
                                      color: AppColors.error,
                                      height: AppSizes.buttonLg,
                                      onPressed: _handleDelete,
                                    ),
                                  ),
                                ],
                              )
                            : PremiumButton(
                                label: currentUserId != null ? 'Message' : 'Sign in to Message',
                                icon: Icon(
                                  Icons.forum_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                style: PremiumButtonStyle.gradient,
                                height: AppSizes.buttonLg,
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
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
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
                    icon: const Icon(Icons.share_rounded, size: AppSizes.iconSm, color: Colors.white),
                    onPressed: _handleShare,
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
}
