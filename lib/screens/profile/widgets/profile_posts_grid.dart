import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/listing_model.dart';
import '../../../widgets/premium_button.dart';

class ProfilePostsGrid extends StatelessWidget {
  final List<ListingModel> listings;
  final bool isLoading;
  final bool isOwnProfile;
  final VoidCallback? onAddFirstItem;

  const ProfilePostsGrid({
    super.key,
    required this.listings,
    this.isLoading = false,
    this.isOwnProfile = true,
    this.onAddFirstItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        ),
      );
    }

    if (listings.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 32,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              SizedBox(height: AppSizes.s16),
              Text(
                isOwnProfile
                    ? 'No items listed yet'
                    : 'This user has no items listed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white54 : AppColors.textMuted,
                ),
              ),
              if (isOwnProfile && onAddFirstItem != null) ...[
                SizedBox(height: AppSizes.s20),
                PremiumButton(
                  label: 'List your first item',
                  style: PremiumButtonStyle.gradient,
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  onPressed: onAddFirstItem,
                  height: AppSizes.buttonMd,
                  width: 220,
                  borderRadius: AppSizes.radiusMd,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ProfileListingCard(listing: listings[index]),
          childCount: listings.length,
        ),
      ),
    );
  }
}

class _ProfileListingCard extends StatelessWidget {
  final ListingModel listing;

  const _ProfileListingCard({required this.listing});

  Color _listingTypeColor(String type) {
    return switch (type) {
      'sell' => const Color(0xFF10B981),
      'exchange' => Colors.blue,
      'donate' => const Color(0xFFE11D48),
      'sellExchange' => Colors.purple,
      'sell_exchange' => Colors.purple,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final thumbnail = listing.images.isNotEmpty ? listing.images.first.url : null;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.postDetails,
          arguments: {'postId': listing.id},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.border.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: thumbnail != null && thumbnail.isNotEmpty
                          ? ClipRRect(
                              child: Image.network(thumbnail, fit: BoxFit.cover),
                            )
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              child: Icon(
                                Icons.inventory_2_rounded,
                                color: AppColors.primary.withValues(alpha: 0.3),
                                size: 36,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _listingTypeColor(listing.listingType).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.listingTypeLabel,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          listing.conditionLabel,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSizes.s8),
                    Text(
                      listing.priceLabel.isNotEmpty
                          ? listing.priceLabel
                          : listing.listingTypeLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
