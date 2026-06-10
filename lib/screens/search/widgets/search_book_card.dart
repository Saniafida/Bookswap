import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/search_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/listing_model.dart';

class SearchBookCard extends StatelessWidget {
  final ListingModel listing;

  const SearchBookCard({super.key, required this.listing});

  Color _typeColor(String type) {
    return switch (type) {
      'sell' => const Color(0xFF10B981),
      'exchange' => const Color(0xFF3B82F6),
      'donate' => const Color(0xFFE11D48),
      'sellExchange' => const Color(0xFF8B5CF6),
      'sell_exchange' => const Color(0xFF8B5CF6),
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final thumbnail = listing.images.isNotEmpty ? listing.images.first.url : null;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.postDetails,
        arguments: {'postId': listing.id},
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.bgCardDark.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.border.withValues(alpha: 0.4),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: thumbnail != null && thumbnail.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppSizes.radiusMd),
                                ),
                                child: Image.network(
                                  thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholder(context),
                                ),
                              )
                            : _placeholder(context),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _typeColor(listing.listingType),
                                _typeColor(listing.listingType)
                                    .withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: _typeColor(listing.listingType)
                                    .withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            SearchConstants.listingTypeLabel(listing.listingType),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      if (listing.categoryName != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              listing.categoryName!,
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
                  padding:
                      const EdgeInsets.fromLTRB(AppSizes.s10, 8, AppSizes.s10, AppSizes.s10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing.conditionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            listing.priceLabel.isNotEmpty
                                ? listing.priceLabel
                                : listing.listingTypeLabel,
                            style: GoogleFonts.poppins(
                              color: _typeColor(listing.listingType),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (listing.ownerName != null)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                backgroundImage:
                                    listing.ownerAvatarUrl != null
                                        ? NetworkImage(listing.ownerAvatarUrl!)
                                        : null,
                                child: listing.ownerAvatarUrl == null
                                    ? Text(
                                        (listing.ownerName?.isNotEmpty == true
                                                ? listing.ownerName![0]
                                                : 'U')
                                            .toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          color: AppColors.primary,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurfaceDark : AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusMd),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_rounded,
          size: 32,
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}
