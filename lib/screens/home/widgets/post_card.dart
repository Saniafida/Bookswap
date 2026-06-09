import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/post_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../widgets/premium_button.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final isOwner = currentUserId == widget.post.userId;
    final timeAgo = _formatTimeAgo(widget.post.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16, vertical: AppSizes.s8),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.postDetails,
          arguments: {'postId': widget.post.id},
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, theme, isDark, isOwner, timeAgo),
                  _buildCoverImage(theme, isDark),
                  _buildBody(context, theme, isDark, isOwner, currentUserId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark,
      bool isOwner, String timeAgo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s16, AppSizes.s14, AppSizes.s16, AppSizes.s10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.profile,
              arguments: {'userId': widget.post.userId},
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: widget.post.ownerAvatarUrl != null
                    ? Image.network(
                        widget.post.ownerAvatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _avatarFallback(theme),
                      )
                    : _avatarFallback(theme),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.ownerName ?? 'Unknown Reader',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.s2),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12,
                        color: isDark ? Colors.white38 : AppColors.textMuted),
                    const SizedBox(width: AppSizes.s4),
                    Text(
                      timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                      ),
                    ),
                    if (widget.post.location != null &&
                        widget.post.location!.isNotEmpty) ...[
                      const SizedBox(width: AppSizes.s8),
                      Icon(Icons.location_on_rounded,
                          size: 12,
                          color: isDark ? Colors.white38 : AppColors.textMuted),
                      const SizedBox(width: AppSizes.s2),
                      Flexible(
                        child: Text(
                          widget.post.location!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color:
                                isDark ? Colors.white38 : AppColors.textMuted,
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
          if (isOwner)
            _buildPill(
              label: 'Mine',
              bgColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              textColor: theme.colorScheme.primary,
            )
          else
            _buildListingTypeBadge(widget.post.listingType),
        ],
      ),
    );
  }

  Widget _buildCoverImage(ThemeData theme, bool isDark) {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.s14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.bgLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.post.imageUrl != null &&
              widget.post.imageUrl!.isNotEmpty)
            ClipRRect(
              child: Image.network(
                widget.post.imageUrl!,
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
                  return _shimmerPlaceholder(theme);
                },
                errorBuilder: (_, __, ___) => _bookPlaceholder(theme),
              ),
            )
          else
            _bookPlaceholder(theme),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 12,
            left: 12,
            child: _buildPill(
              label: _conditionLabel(widget.post.condition),
              bgColor: Colors.black.withValues(alpha: 0.6),
              textColor: Colors.white,
            ),
          ),

          if (widget.post.category != null &&
              widget.post.category!.isNotEmpty)
            Positioned(
              bottom: 12,
              left: 12,
              child: _buildPill(
                label: widget.post.category!,
                bgColor: Colors.black.withValues(alpha: 0.6),
                textColor: Colors.white,
              ),
            ),

          if (widget.post.price != null &&
              (widget.post.listingType == ListingType.sell ||
               widget.post.listingType == ListingType.both))
            Positioned(
              bottom: 12,
              right: 12,
              child: _buildPill(
                label: '\$${widget.post.price!.toStringAsFixed(0)}',
                bgColor: theme.colorScheme.primary.withValues(alpha: 0.85),
                textColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, bool isDark,
      bool isOwner, String? currentUserId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s16, AppSizes.s12, AppSizes.s16, AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.s2),
          Text(
            'by ${widget.post.author}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          if (widget.post.description != null &&
              widget.post.description!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.s10),
            Text(
              widget.post.description!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: (isDark ? Colors.white60 : AppColors.textPrimary)
                    .withValues(alpha: 0.75),
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppSizes.s14),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.border,
            height: 1,
          ),
          const SizedBox(height: AppSizes.s14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.listingType == ListingType.swap
                          ? 'Exchange Value'
                          : widget.post.listingType == ListingType.donate
                              ? 'Listing Type'
                              : 'Price',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? Colors.white38 : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s2),
                    Row(
                      children: [
                        if (widget.post.listingType == ListingType.swap) ...[
                          Icon(Icons.swap_horiz_rounded,
                              color: theme.colorScheme.primary, size: 16),
                          const SizedBox(width: AppSizes.s4),
                        ] else if (widget.post.listingType == ListingType.donate) ...[
                          Icon(Icons.volunteer_activism_rounded,
                              color: const Color(0xFFE11D48), size: 16),
                          const SizedBox(width: AppSizes.s4),
                        ],
                        Text(
                          _priceLabel(widget.post),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (!isOwner)
                _MessageButton(
                  post: widget.post,
                  currentUserId: currentUserId,
                  theme: theme,
                )
              else
                PremiumButton(
                  label: 'View',
                  icon: const Icon(Icons.visibility_rounded, size: 15),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.postDetails,
                    arguments: {'postId': widget.post.id},
                  ),
                  style: PremiumButtonStyle.secondary,
                  height: AppSizes.buttonSm,
                  width: 100,
                  borderRadius: AppSizes.radiusMd,
                  fontSize: 13,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(ThemeData theme) {
    final letter = widget.post.ownerName?.isNotEmpty == true
        ? widget.post.ownerName![0].toUpperCase()
        : 'U';
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _shimmerPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _bookPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.tertiary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 52,
              color: theme.colorScheme.primary.withValues(alpha: 0.35)),
          const SizedBox(height: AppSizes.s8),
          Text(
            'No Cover',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s10, vertical: AppSizes.s4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildListingTypeBadge(ListingType type) {
    final (label, bg, fg) = switch (type) {
      ListingType.swap => ('Swap', const Color(0xFF1D4ED8), Colors.white),
      ListingType.sell => ('Sell', const Color(0xFF059669), Colors.white),
      ListingType.both => ('Swap/Sell', const Color(0xFF7C3AED), Colors.white),
      ListingType.donate => ('Donate', const Color(0xFFE11D48), Colors.white),
    };
    return _buildPill(label: label, bgColor: bg, textColor: fg);
  }

  String _priceLabel(PostModel post) {
    return switch (post.listingType) {
      ListingType.swap => 'Swap Only',
      ListingType.both =>
        post.price != null ? '\$${post.price!.toStringAsFixed(2)}' : 'Swap/Sell',
      ListingType.sell =>
        post.price != null ? '\$${post.price!.toStringAsFixed(2)}' : 'Free',
      ListingType.donate => 'Free (Donation)',
    };
  }

  String _conditionLabel(BookCondition c) => switch (c) {
        BookCondition.brandNew => 'Brand New',
        BookCondition.likeNew => 'Like New',
        BookCondition.good => 'Good',
        BookCondition.fair => 'Fair',
        BookCondition.poor => 'Poor',
      };

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _MessageButton extends StatefulWidget {
  final PostModel post;
  final String? currentUserId;
  final ThemeData theme;

  const _MessageButton({
    required this.post,
    required this.currentUserId,
    required this.theme,
  });

  @override
  State<_MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends State<_MessageButton> {
  bool _loading = false;

  Future<void> _handleTap() async {
    final ctx = context;
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Sign in to send a message.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final chatProvider =
          Provider.of<ChatProvider>(ctx, listen: false);
      final chatId = await chatProvider.getOrCreateChat(
          widget.currentUserId!, widget.post.userId);
      if (!mounted) return;
      if (chatId != null) {
        Navigator.pushNamed(
          ctx,
          AppRoutes.chat,
          arguments: {
            'chatId': chatId,
            'participantName': widget.post.ownerName,
            'participantAvatarUrl': widget.post.ownerAvatarUrl,
          },
        );
      } else {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Could not start conversation.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: widget.theme.colorScheme.primary,
              ),
            )
          : PremiumButton(
              key: const ValueKey('button'),
              label: 'Message',
              icon: const Icon(Icons.forum_rounded, size: 15),
              onPressed: _handleTap,
              style: PremiumButtonStyle.primary,
              height: AppSizes.buttonSm,
              width: 110,
              borderRadius: AppSizes.radiusMd,
              fontSize: 13,
            ),
    );
  }
}
