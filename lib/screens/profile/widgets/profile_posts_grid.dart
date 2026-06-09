import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/post_model.dart';
import '../../../widgets/premium_button.dart';

class ProfilePostsGrid extends StatelessWidget {
  final List<PostModel> posts;
  final bool isLoading;
  final bool isOwnProfile;
  final VoidCallback? onAddFirstBook;

  const ProfilePostsGrid({
    super.key,
    required this.posts,
    this.isLoading = false,
    this.isOwnProfile = true,
    this.onAddFirstBook,
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

    if (posts.isEmpty) {
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
                  Icons.menu_book_rounded,
                  size: 32,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              SizedBox(height: AppSizes.s16),
              Text(
                isOwnProfile
                    ? 'No books listed yet'
                    : 'This reader has no books listed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white54 : AppColors.textMuted,
                ),
              ),
              if (isOwnProfile && onAddFirstBook != null) ...[
                SizedBox(height: AppSizes.s20),
                PremiumButton(
                  label: 'List your first book',
                  style: PremiumButtonStyle.gradient,
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  onPressed: onAddFirstBook,
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
          (context, index) => _ProfilePostCard(post: posts[index]),
          childCount: posts.length,
        ),
      ),
    );
  }
}

class _ProfilePostCard extends StatelessWidget {
  final PostModel post;

  const _ProfilePostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.postDetails,
          arguments: {'postId': post.id},
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
                      child: post.imageUrl != null && post.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              child: Image.network(post.imageUrl!, fit: BoxFit.cover),
                            )
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              child: Icon(
                                Icons.book_rounded,
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
                          color: _listingTypeColor(post.listingType).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.listingType == ListingType.swap
                              ? 'Swap'
                              : post.listingType == ListingType.sell
                                  ? 'Sell'
                                  : post.listingType == ListingType.donate
                                      ? 'Donate'
                                      : 'Both',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
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
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSizes.s2),
                    Text(
                      'by ${post.author}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        color: isDark ? Colors.white54 : AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: AppSizes.s8),
                    Text(
                      post.listingType == ListingType.swap
                          ? 'Swap Only'
                          : post.listingType == ListingType.donate
                              ? 'Free (Donation)'
                              : post.price != null
                                  ? '\$${post.price!.toStringAsFixed(2)}'
                                  : 'Free',
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

  Color _listingTypeColor(ListingType type) {
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
