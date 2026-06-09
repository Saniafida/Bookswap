import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/post_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../widgets/announcement_banner.dart';
import '../../widgets/premium_button.dart';
import 'widgets/category_list.dart';
import 'widgets/home_header.dart';
import 'widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All Books';
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTopBtn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<PostProvider>(context, listen: false);
      p.fetchPosts();
      p.subscribeToPosts();
      final ap = Provider.of<AnnouncementProvider>(context, listen: false);
      ap.fetchAnnouncements();
      ap.subscribeToAnnouncements();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 300;
    if (shouldShow != _showScrollTopBtn) {
      setState(() => _showScrollTopBtn = shouldShow);
    }
  }

  @override
  void dispose() {
    Provider.of<PostProvider>(context, listen: false).unsubscribePosts();
    Provider.of<AnnouncementProvider>(context, listen: false)
        .unsubscribeFromAnnouncements();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () =>
                  Provider.of<PostProvider>(context, listen: false)
                      .fetchPosts(),
              color: theme.colorScheme.primary,
              backgroundColor:
                  isDark ? theme.colorScheme.surface : Colors.white,
              strokeWidth: 2.5,
              displacement: 24,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Consumer<AnnouncementProvider>(
                      builder: (_, ap, __) {
                        if (!ap.hasVisible) return const SizedBox.shrink();
                        final a = ap.topAnnouncement!;
                        return AnnouncementBanner(
                          message: a.title,
                        );
                      },
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: HomeHeader(
                      onSearchChanged: (q) =>
                          setState(() => _searchQuery = q.toLowerCase()),
                      onFilterPressed: () =>
                          _showFilterSheet(context, theme),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.s12),
                      child: CategoryList(
                        onCategorySelected: (c) =>
                            setState(() => _selectedCategory = c),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.s20, 0, AppSizes.s20, AppSizes.s8),
                      child: Row(
                        children: [
                          Text(
                            _selectedCategory == 'All Books'
                                ? 'Latest Listings'
                                : _selectedCategory,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Consumer<PostProvider>(
                            builder: (_, p, __) {
                              if (p.posts.isEmpty) return const SizedBox();
                              final count = _filteredPosts(p).length;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.s10,
                                    vertical: AppSizes.s4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusFull),
                                ),
                                child: Text(
                                  '$count result${count == 1 ? '' : 's'}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  Consumer<PostProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading && provider.posts.isEmpty) {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _ShimmerCard(isDark: theme.brightness == Brightness.dark),
                            childCount: 3,
                          ),
                        );
                      }

                      if (provider.status == PostStatus.error) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _ErrorState(
                            message: provider.errorMessage,
                            onRetry: () => provider.fetchPosts(),
                          ),
                        );
                      }

                      final posts = _filteredPosts(provider);

                      if (posts.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(
                            searchQuery: _searchQuery,
                            category: _selectedCategory,
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final isLast = index == posts.length - 1;
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: isLast ? 120 : 0),
                              child: PostCard(post: posts[index]),
                            );
                          },
                          childCount: posts.length,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: _showScrollTopBtn ? 110 : -60,
              right: AppSizes.s20,
              child: AnimatedOpacity(
                opacity: _showScrollTopBtn ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: FloatingActionButton.small(
                  heroTag: 'scroll_top',
                  onPressed: () => _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(Icons.keyboard_arrow_up_rounded,
                      size: AppSizes.iconMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List _filteredPosts(PostProvider provider) {
    return provider.posts.where((post) {
      final q = _searchQuery;
      final matchSearch = q.isEmpty ||
          post.title.toLowerCase().contains(q) ||
          post.author.toLowerCase().contains(q) ||
          (post.description?.toLowerCase().contains(q) ?? false);

      final matchCategory = _selectedCategory == 'All Books' ||
          (post.category?.toLowerCase() ==
              _selectedCategory.toLowerCase());

      return matchSearch && matchCategory;
    }).toList();
  }

  void _showFilterSheet(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? theme.colorScheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (ctx) => _FilterSheet(theme: theme, isDark: isDark),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;
  const _FilterSheet({required this.theme, required this.isDark});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int _typeIndex = 0;
  int _conditionIndex = 0;

  final _types = ['All', 'Swap', 'Sell', 'Swap/Sell'];
  final _conditions = ['Any', 'Brand New', 'Like New', 'Good', 'Fair'];

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.s20, AppSizes.s12, AppSizes.s20, AppSizes.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSizes.s2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s16),
            Text(
              'Filter Listings',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: widget.isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.s20),
            _filterSection('Listing Type', _types, _typeIndex,
                (i) => setState(() => _typeIndex = i), t),
            const SizedBox(height: AppSizes.s16),
            _filterSection('Condition', _conditions, _conditionIndex,
                (i) => setState(() => _conditionIndex = i), t),
            const SizedBox(height: AppSizes.s24),
            PremiumButton(
              label: 'Apply Filters',
              onPressed: () => Navigator.pop(context),
              style: PremiumButtonStyle.gradient,
              height: AppSizes.buttonLg,
              borderRadius: AppSizes.radiusMd,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterSection(String title, List<String> items, int selected,
      ValueChanged<int> onSelect, ThemeData t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.s10),
        Wrap(
          spacing: AppSizes.s8,
          runSpacing: AppSizes.s8,
          children: List.generate(items.length, (i) {
            final isSel = i == selected;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s14, vertical: AppSizes.s8),
                decoration: BoxDecoration(
                  gradient: isSel ? AppColors.primaryGradient : null,
                  color: isSel
                      ? null
                      : t.colorScheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: isSel
                        ? Colors.transparent
                        : t.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  items[i],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : t.colorScheme.primary,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String searchQuery;
  final String category;
  const _EmptyState({required this.searchQuery, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasQuery = searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.menu_book_rounded,
                size: 44,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSizes.s20),
            Text(
              hasQuery ? 'No books found' : 'Nothing here yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              hasQuery
                  ? 'No results for "$searchQuery".\nTry a different search.'
                  : category == 'All Books'
                      ? 'Be the first to list a book!'
                      : 'No books listed in $category yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white54 : AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  final bool isDark;
  const _ShimmerCard({required this.isDark});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 0.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = theme.colorScheme.outline.withValues(alpha: _anim.value * 0.6);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s8),
          child: Container(
            padding: AppSizes.cardPadding,
            decoration: BoxDecoration(
              color: widget.isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _box(40, 40, shimmer, radius: AppSizes.radiusFull),
                    const SizedBox(width: AppSizes.s10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(110, 12, shimmer),
                        const SizedBox(height: AppSizes.s6),
                        _box(70, 10, shimmer),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s14),
                _box(double.infinity, 240, shimmer, radius: AppSizes.radiusMd),
                const SizedBox(height: AppSizes.s14),
                _box(180, 14, shimmer),
                const SizedBox(height: AppSizes.s6),
                _box(120, 11, shimmer),
                const SizedBox(height: AppSizes.s14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _box(90, 22, shimmer),
                    _box(100, 38, shimmer, radius: AppSizes.radiusMd),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _box(double w, double h, Color color, {double radius = AppSizes.radiusSm}) =>
      Container(
        width: w == double.infinity ? null : w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const _ErrorState({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.s16),
            Text(
              'Could not load books',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              message ?? 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSizes.s24),
            PremiumButton(
              label: 'Retry',
              icon: const Icon(Icons.refresh_rounded, size: AppSizes.iconSm),
              onPressed: onRetry,
              style: PremiumButtonStyle.primary,
              height: AppSizes.buttonMd,
              width: 140,
              borderRadius: AppSizes.radiusMd,
            ),
          ],
        ),
      ),
    );
  }
}
