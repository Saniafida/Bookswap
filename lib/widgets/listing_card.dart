import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/routes/app_routes.dart';
import '../data/models/listing_model.dart';

class ListingCard extends StatefulWidget {
  final ListingModel listing;

  const ListingCard({super.key, required this.listing});

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
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
      'exchange'      => AppColors.typeExchange,
      'sell'          => AppColors.typeSell,
      'sellExchange'  => AppColors.typeSellExchange,
      'sell_exchange' => AppColors.typeSellExchange,
      'donate'        => AppColors.typeDonate,
      _               => AppColors.primary,
    };
  }

  String _conditionLabel(String condition) {
    return switch (condition) {
      'brandNew' => 'Brand New',
      'likeNew'  => 'Like New',
      'good'     => 'Good',
      'fair'     => 'Fair',
      'poor'     => 'Poor',
      _          => condition,
    };
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final timeAgo = _formatTimeAgo(listing.createdAt);
    final coverUrl =
        listing.images.isNotEmpty ? listing.images.first.url : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16, vertical: AppSizes.s8),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.listingDetails,
          arguments: {'listingId': listing.id},
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.7),
                width: 1,
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(timeAgo, listing),
                  _buildCoverImage(coverUrl, listing),
                  _buildBody(listing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String timeAgo, ListingModel listing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s16, AppSizes.s14, AppSizes.s16, AppSizes.s10),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.profile,
              arguments: {'userId': listing.userId},
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: listing.ownerAvatarUrl == null
                    ? AppColors.primaryGradient
                    : null,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: listing.ownerAvatarUrl != null
                    ? Image.network(
                        listing.ownerAvatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _avatarFallback(listing),
                      )
                    : _avatarFallback(listing),
              ),
            ),
          ),

          const SizedBox(width: AppSizes.s10),

          // Name + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.ownerName ?? 'Swaply User',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (listing.location != null &&
                        listing.location!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_rounded,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          listing.location!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Type badge
          _buildTypeBadge(listing),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String? coverUrl, ListingModel listing) {
    return Container(
      height: 230,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.s14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        color: AppColors.bgSurface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (coverUrl != null)
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              frameBuilder:
                  (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  if (!_imageLoaded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _imageLoaded = true);
                    });
                  }
                  return AnimatedOpacity(
                    opacity: _imageLoaded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 350),
                    child: child,
                  );
                }
                return _shimmerPlaceholder();
              },
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            )
          else
            _imagePlaceholder(),

          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 70,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Condition pill (top-left)
          Positioned(
            top: 10,
            left: 10,
            child: _buildPill(
              label: _conditionLabel(listing.condition),
              bgColor: Colors.black.withValues(alpha: 0.55),
              textColor: Colors.white,
            ),
          ),

          // Category pill (bottom-left)
          if (listing.categoryName != null &&
              listing.categoryName!.isNotEmpty)
            Positioned(
              bottom: 10,
              left: 10,
              child: _buildPill(
                label: listing.categoryName!,
                bgColor: AppColors.primary.withValues(alpha: 0.80),
                textColor: Colors.white,
              ),
            ),

          // Price pill (bottom-right)
          if (listing.price != null &&
              (listing.listingType == 'sell' ||
                  listing.listingType == 'sell_exchange'))
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Rs ${listing.price!.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ListingModel listing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s16, AppSizes.s12, AppSizes.s16, AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            listing.title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (listing.description != null &&
              listing.description!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.s8),
            Text(
              listing.description!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSizes.s12),
          Divider(
            color: AppColors.border.withValues(alpha: 0.6),
            height: 1,
          ),
          const SizedBox(height: AppSizes.s12),

          // Price / Type row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.listingType == 'exchange'
                          ? 'Exchange Value'
                          : listing.listingType == 'donate'
                              ? 'Listing Type'
                              : 'Price',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          listing.listingTypeIcon,
                          color: _getListingTypeColor(listing.listingType),
                          size: 16,
                        ),
                        const SizedBox(width: AppSizes.s4),
                        Flexible(
                          child: Text(
                            listing.priceLabel.isNotEmpty
                                ? listing.priceLabel
                                : listing.listingTypeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: _getListingTypeColor(listing.listingType),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chat quick action
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s14, vertical: AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  'View →',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(ListingModel listing) {
    final color = _getListingTypeColor(listing.listingType);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s10, vertical: AppSizes.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        listing.listingTypeLabel,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _avatarFallback(ListingModel listing) {
    final letter = listing.ownerName?.isNotEmpty == true
        ? listing.ownerName![0].toUpperCase()
        : 'S';
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _shimmerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bgSurface,
            AppColors.border.withValues(alpha: 0.3),
            AppColors.bgSurface,
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.08),
            AppColors.roseGold.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.30)),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: textColor,
        ),
      ),
    );
  }
}
