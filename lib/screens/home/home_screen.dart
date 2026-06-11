import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/listing_model.dart';
import '../../providers/home_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/announcement_banner.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/swaply_background.dart';
import 'widgets/category_list.dart';
import 'widgets/home_header.dart';

class _HomeSection {
  final String title;
  final List<ListingModel> listings;
  const _HomeSection(this.title, this.listings);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _typeFilter;
  String? _conditionFilter;
  double? _priceMin;
  double? _priceMax;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTopBtn = false;
  int _heroBannerPage = 0;
  final PageController _heroPageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hp = context.read<HomeProvider>();
      hp.fetchHomeData();
      final lp = context.read<ListingProvider>();
      lp.fetchListings();
      lp.subscribeToListings();
      final ap = context.read<AnnouncementProvider>();
      ap.fetchAnnouncements();
      ap.subscribeToAnnouncements();
    });
    _scrollController.addListener(_onScroll);

    // Auto-scroll hero banner
    Future.delayed(const Duration(seconds: 3), _startHeroAutoScroll);
  }

  void _startHeroAutoScroll() {
    if (!mounted) return;
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_heroBannerPage + 1) % 3;
      _heroPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      _startHeroAutoScroll();
    });
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 300;
    if (shouldShow != _showScrollTopBtn) {
      setState(() => _showScrollTopBtn = shouldShow);
    }
  }

  @override
  void dispose() {
    context.read<ListingProvider>().unsubscribeListings();
    context.read<AnnouncementProvider>().unsubscribeFromAnnouncements();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<HomeProvider>().refreshHome(),
      context.read<ListingProvider>().fetchListings(refresh: true),
    ]);
  }

  List<ListingModel> _filteredListings(ListingProvider provider) {
    return provider.listings.where((l) {
      final q = _searchQuery.toLowerCase().trim();
      final matchSearch = q.isEmpty ||
          l.title.toLowerCase().contains(q) ||
          (l.description?.toLowerCase().contains(q) ?? false) ||
          (l.ownerName?.toLowerCase().contains(q) ?? false);

      final matchCategory = _selectedCategoryId == null ||
          l.categoryId == _selectedCategoryId;

      final matchType = _typeFilter == null || l.listingType == _typeFilter;
      final matchCondition =
          _conditionFilter == null || l.condition == _conditionFilter;
      final matchPrice = (_priceMin == null || (l.price ?? 0) >= _priceMin!) &&
          (_priceMax == null || (l.price ?? double.infinity) <= _priceMax!);

      return matchSearch &&
          matchCategory &&
          matchType &&
          matchCondition &&
          matchPrice;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SwaplyBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.primary,
                  backgroundColor: Colors.white,
                  strokeWidth: 2.5,
                  displacement: 24,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      // Announcement banner
                      SliverToBoxAdapter(
                        child: Consumer<AnnouncementProvider>(
                          builder: (_, ap, __) {
                            if (!ap.hasVisible) return const SizedBox.shrink();
                            final a = ap.topAnnouncement!;
                            return AnnouncementBanner(message: a.title);
                          },
                        ),
                      ),

                      // Header with greeting + search
                      SliverToBoxAdapter(
                        child: HomeHeader(
                          onSearchChanged: (q) =>
                              setState(() => _searchQuery = q),
                          onFilterPressed: () =>
                              _showFilterSheet(context, theme),
                        ),
                      ),

                      // Hero Banner
                      SliverToBoxAdapter(
                        child: _HeroBanner(
                          pageController: _heroPageController,
                          currentPage: _heroBannerPage,
                          onPageChanged: (i) =>
                              setState(() => _heroBannerPage = i),
                        ),
                      ),

                      // Top Categories label
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Top Categories',
                          onSeeAll: () {},
                        ),
                      ),

                      // Category chips
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.s8),
                          child: CategoryList(
                            onCategorySelected: (id) =>
                                setState(() => _selectedCategoryId = id),
                          ),
                        ),
                      ),

                      // Featured + Popular + Recent horizontal rows
                      Consumer<HomeProvider>(
                        builder: (context, home, _) {
                          if (home.isLoading &&
                              home.status == HomeStatus.loading) {
                            return SliverToBoxAdapter(
                              child: _buildShimmerSections(),
                            );
                          }
                          if (home.status == HomeStatus.error) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: _ErrorState(
                                message: home.errorMessage,
                                onRetry: () => home.fetchHomeData(),
                              ),
                            );
                          }

                          final sections = <_HomeSection>[
                            if (home.featuredListings.isNotEmpty)
                              _HomeSection(
                                  'Featured For You', home.featuredListings),
                            if (home.popularListings.isNotEmpty)
                              _HomeSection(
                                  'Trending Now', home.popularListings),
                            if (home.recentListings.isNotEmpty)
                              _HomeSection(
                                  'Nearby Items', home.recentListings),
                          ];

                          return SliverList(
                            delegate: SliverChildListDelegate(
                              sections
                                  .map((s) => _SectionRow(
                                        title: s.title,
                                        listings: s.listings,
                                        isDark: isDark,
                                        theme: theme,
                                      ))
                                  .toList(),
                            ),
                          );
                        },
                      ),

                      // All Listings header
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'All Listings',
                          trailing: Consumer<ListingProvider>(
                            builder: (_, lp, __) {
                              if (lp.listings.isEmpty)
                                return const SizedBox();
                              final count = _filteredListings(lp).length;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.s10,
                                    vertical: AppSizes.s4),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusFull),
                                  boxShadow: AppColors.primaryGlowShadow,
                                ),
                                child: Text(
                                  '$count result${count == 1 ? '' : 's'}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          onSeeAll: null,
                        ),
                      ),

                      // All listings
                      Consumer<ListingProvider>(
                        builder: (context, provider, _) {
                          if (provider.isLoading && provider.listings.isEmpty) {
                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _ShimmerCard(
                                    isDark: theme.brightness ==
                                        Brightness.dark),
                                childCount: 3,
                              ),
                            );
                          }

                          if (provider.status == ListingsLoadState.error) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: _ErrorState(
                                message: provider.errorMessage,
                                onRetry: () =>
                                    provider.fetchListings(refresh: true),
                              ),
                            );
                          }

                          final listings = _filteredListings(provider);

                          if (listings.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyState(
                                searchQuery: _searchQuery,
                                hasFilter: _selectedCategoryId != null ||
                                    _typeFilter != null ||
                                    _conditionFilter != null,
                              ),
                            );
                          }

                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final isLast = index == listings.length - 1;
                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: isLast ? 120 : 0),
                                  child: ListingCard(listing: listings[index]),
                                );
                              },
                              childCount: listings.length,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Scroll-to-top FAB
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
      ),
    );
  }

  Widget _buildShimmerSections() {
    return Column(
      children: [
        _buildShimmerRow(),
        _buildShimmerRow(),
      ],
    );
  }

  Widget _buildShimmerRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.s20, AppSizes.s16, AppSizes.s20, AppSizes.s12),
          child: Container(
            width: 140,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSizes.s4),
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
            itemCount: 4,
            itemBuilder: (_, __) {
              return Container(
                width: 155,
                margin: const EdgeInsets.only(right: AppSizes.s12),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (ctx) => _FilterSheet(
        theme: theme,
        isDark: isDark,
        selectedType: _typeFilter,
        selectedCondition: _conditionFilter,
        minPrice: _priceMin,
        maxPrice: _priceMax,
        onApply: (type, condition, minPrice, maxPrice) {
          setState(() {
            _typeFilter = type;
            _conditionFilter = condition;
            _priceMin = minPrice;
            _priceMax = maxPrice;
          });
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Banner
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _HeroBanner({
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  static const _slides = [
    _HeroSlide(
      headline: 'Find. Swap.\nSell. Donate.',
      sub: 'Everything you need,\nsomeone is ready to swap.',
      btnLabel: 'Explore Now',
      accentColor: Color(0xFFC54B8C),
    ),
    _HeroSlide(
      headline: 'Give Books\nNew Life.',
      sub: 'Share stories,\nbuild community.',
      btnLabel: 'Donate Now',
      accentColor: Color(0xFF8B2352),
    ),
    _HeroSlide(
      headline: 'Your Treasure\nAwaits.',
      sub: 'Discover hidden gems\nnear you.',
      btnLabel: 'Discover',
      accentColor: Color(0xFF6B1B3E),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s16, 0, AppSizes.s16, AppSizes.s8),
      child: Column(
        children: [
          SizedBox(
            height: 205,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: _slides.length,
              itemBuilder: (_, i) => _HeroBannerCard(slide: _slides[i]),
            ),
          ),
          const SizedBox(height: AppSizes.s10),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: currentPage == i ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  gradient: currentPage == i
                      ? AppColors.primaryGradient
                      : null,
                  color: currentPage == i
                      ? null
                      : AppColors.border,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSlide {
  final String headline;
  final String sub;
  final String btnLabel;
  final Color accentColor;
  const _HeroSlide({
    required this.headline,
    required this.sub,
    required this.btnLabel,
    required this.accentColor,
  });
}

class _HeroBannerCard extends StatelessWidget {
  final _HeroSlide slide;
  const _HeroBannerCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - AppSizes.s16 * 2;
    // Allow text to take up about 55% of the card width to prevent overlap
    final maxTextWidth = cardWidth * 0.55;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFE8F0),
            const Color(0xFFFFF0E8),
            const Color(0xFFFFE8F5),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: Stack(
          children: [
            // Decorative blobs
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              right: 60,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.roseGold.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Small floating orbs
            Positioned(
              top: 20,
              right: 130,
              child: _FloatingOrb(size: 16, color: AppColors.primaryLight.withValues(alpha: 0.25)),
            ),
            Positioned(
              top: 60,
              right: 90,
              child: _FloatingOrb(size: 10, color: AppColors.roseGold.withValues(alpha: 0.35)),
            ),
            Positioned(
              bottom: 30,
              right: 140,
              child: _FloatingOrb(size: 12, color: AppColors.primaryLight.withValues(alpha: 0.20)),
            ),

            // Left content (vertically centered, constrained, scroll-safe)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s20, vertical: AppSizes.s8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: maxTextWidth,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Headline
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppColors.primaryGradient.createShader(b),
                          child: Text(
                            slide.headline,
                            style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.s6),
                        Text(
                          slide.sub,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSizes.s12),
                        // CTA button
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.s14, vertical: AppSizes.s8),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                              boxShadow: AppColors.primaryGlowShadow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  slide.btnLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.s4),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Right image area — product silhouette decoration
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 160,
              child: _BannerProductDisplay(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _FloatingOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _BannerProductDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Decorative product-like shapes
    return Stack(
      children: [
        // Large circle backdrop
        Positioned(
          right: -30,
          top: 10,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.20),
                  AppColors.roseGold.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Product icon illustrations
        Positioned(
          right: 20,
          top: 25,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow,
            ),
            child: const Icon(Icons.phone_android_rounded,
                color: AppColors.primaryLight, size: 30),
          ),
        ),
        Positioned(
          right: 90,
          top: 60,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.softShadow,
            ),
            child: const Icon(Icons.chair_rounded,
                color: AppColors.roseGold, size: 24),
          ),
        ),
        Positioned(
          right: 25,
          bottom: 30,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(15),
              boxShadow: AppColors.softShadow,
            ),
            child: const Icon(Icons.shopping_bag_rounded,
                color: AppColors.primary, size: 26),
          ),
        ),
        Positioned(
          right: 88,
          bottom: 20,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.30)),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: AppColors.primaryLight, size: 20),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    this.onSeeAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s20, AppSizes.s20, AppSizes.s20, AppSizes.s10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
          if (trailing == null && onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.primaryGradient.createShader(b),
                    child: Text(
                      'See All',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.primaryLight),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Row (Featured / Trending / Nearby)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionRow extends StatelessWidget {
  final String title;
  final List<ListingModel> listings;
  final bool isDark;
  final ThemeData theme;

  const _SectionRow({
    required this.title,
    required this.listings,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isFeatured = title == 'Featured For You';
    final isTrending = title == 'Trending Now';
    final isNearby = title == 'Nearby Items';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, onSeeAll: () {}),
        if (isFeatured || isTrending || isNearby)
          SizedBox(
            height: isFeatured ? 230 : (isTrending ? 185 : 155),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
              physics: const BouncingScrollPhysics(),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final double width = isFeatured ? 165 : (isTrending ? 145 : 110);
                final double rightPadding = isFeatured ? 12 : (isTrending ? 10 : 8);
                return SizedBox(
                  width: width,
                  child: Padding(
                    padding: EdgeInsets.only(right: rightPadding),
                    child: isFeatured
                        ? _FeaturedCard(listing: listings[index])
                        : (isTrending
                            ? _TrendingCard(listing: listings[index])
                            : _NearbyCard(listing: listings[index])),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: AppSizes.s4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Card
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedCard extends StatefulWidget {
  final ListingModel listing;
  const _FeaturedCard({required this.listing});

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _wishlisted = false;

  Color _typeColor(String type) => switch (type) {
        'sell' => const Color(0xFF10B981),
        'exchange' => const Color(0xFF3B82F6),
        'donate' => const Color(0xFFE11D48),
        'sellExchange' || 'sell_exchange' => const Color(0xFF8B5CF6),
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final thumb =
        listing.images.isNotEmpty ? listing.images.first.url : null;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.listingDetails,
        arguments: {'listingId': listing.id},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: AppColors.softShadow,
          border: Border.all(
              color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusLg)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumb != null
                        ? Image.network(thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _imagePlaceholder())
                        : _imagePlaceholder(),
                    // Heart button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _wishlisted = !_wishlisted),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.90),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Icon(
                            _wishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: _wishlisted
                                ? AppColors.error
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(AppSizes.s10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    listing.price != null
                        ? 'PKR ${listing.price!.toStringAsFixed(0)}'
                        : listing.listingTypeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _typeColor(listing.listingType),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (listing.location != null &&
                      listing.location!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 10, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              listing.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppColors.bgSurface,
        child: Center(
          child: Icon(Icons.image_rounded,
              size: 32, color: AppColors.primary.withValues(alpha: 0.25)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Trending Card
// ─────────────────────────────────────────────────────────────────────────────
class _TrendingCard extends StatefulWidget {
  final ListingModel listing;
  const _TrendingCard({required this.listing});

  @override
  State<_TrendingCard> createState() => _TrendingCardState();
}

class _TrendingCardState extends State<_TrendingCard> {
  bool _wishlisted = false;

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final thumb =
        listing.images.isNotEmpty ? listing.images.first.url : null;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.listingDetails,
        arguments: {'listingId': listing.id},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: AppColors.softShadow,
          border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusMd)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumb != null
                        ? Image.network(thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _imgPlaceholder())
                        : _imgPlaceholder(),
                    // Trending badge
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                size: 9, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              'Hot',
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Heart
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _wishlisted = !_wishlisted),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.90),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _wishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 13,
                            color: _wishlisted
                                ? AppColors.error
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.price != null
                        ? 'PKR ${listing.price!.toStringAsFixed(0)}'
                        : listing.listingTypeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: AppColors.bgSurface,
        child: Center(
          child: Icon(Icons.image_rounded,
              size: 28, color: AppColors.primary.withValues(alpha: 0.20)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Nearby Card (list style)
// ─────────────────────────────────────────────────────────────────────────────
class _NearbyCard extends StatefulWidget {
  final ListingModel listing;
  const _NearbyCard({required this.listing});

  @override
  State<_NearbyCard> createState() => _NearbyCardState();
}

class _NearbyCardState extends State<_NearbyCard> {
  bool _wishlisted = false;

  Color _typeColor(String type) => switch (type) {
        'sell' => const Color(0xFF10B981),
        'exchange' => const Color(0xFF3B82F6),
        'donate' => const Color(0xFFE11D48),
        'sellExchange' || 'sell_exchange' => const Color(0xFF8B5CF6),
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final thumb =
        listing.images.isNotEmpty ? listing.images.first.url : null;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.listingDetails,
        arguments: {'listingId': listing.id},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: AppColors.softShadow,
          border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusMd)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumb != null
                        ? Image.network(thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _imgPlaceholder())
                        : _imgPlaceholder(),
                    // Distance badge (top-left)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 6, color: Colors.white),
                            const SizedBox(width: 1),
                            Text(
                              'Nearby',
                              style: GoogleFonts.poppins(
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Heart
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _wishlisted = !_wishlisted),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.90),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _wishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 10,
                            color: _wishlisted
                                ? AppColors.error
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    listing.price != null
                        ? 'PKR ${listing.price!.toStringAsFixed(0)}'
                        : listing.listingTypeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _typeColor(listing.listingType),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (listing.location != null &&
                      listing.location!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        const Icon(Icons.near_me_rounded,
                            size: 7, color: AppColors.textMuted),
                        const SizedBox(width: 1.5),
                        Expanded(
                          child: Text(
                            listing.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 7.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: AppColors.bgSurface,
        child: const Center(
          child: Icon(Icons.image_rounded,
              size: 18, color: AppColors.border),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Sheet (unchanged logic)
// ─────────────────────────────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;
  final String? selectedType;
  final String? selectedCondition;
  final double? minPrice;
  final double? maxPrice;
  final void Function(String?, String?, double?, double?) onApply;

  const _FilterSheet({
    required this.theme,
    required this.isDark,
    this.selectedType,
    this.selectedCondition,
    this.minPrice,
    this.maxPrice,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int _typeIndex = 0;
  int _conditionIndex = 0;
  int _categoryIndex = 0;
  final TextEditingController _minCtrl = TextEditingController();
  final TextEditingController _maxCtrl = TextEditingController();

  final _types = ['All', 'sell', 'exchange', 'donate', 'sell_exchange'];
  final _typeLabels = ['All', 'Sell', 'Exchange', 'Donate', 'Sell / Exchange'];
  final _conditions = ['', 'brandNew', 'likeNew', 'good', 'fair', 'poor'];
  final _conditionLabels = [
    'Any', 'Brand New', 'Like New', 'Good', 'Fair', 'Poor'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedType != null) {
      final idx = _types.indexOf(widget.selectedType!);
      if (idx >= 0) _typeIndex = idx;
    }
    if (widget.selectedCondition != null) {
      final idx = _conditions.indexOf(widget.selectedCondition!);
      if (idx >= 0) _conditionIndex = idx;
    }
    if (widget.minPrice != null) {
      _minCtrl.text = widget.minPrice!.toStringAsFixed(0);
    }
    if (widget.maxPrice != null) {
      _maxCtrl.text = widget.maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final isDark = widget.isDark;

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
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Filter Listings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _typeIndex = 0;
                      _conditionIndex = 0;
                      _categoryIndex = 0;
                      _minCtrl.clear();
                      _maxCtrl.clear();
                    });
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _filterSection('Listing Type', _typeLabels, _typeIndex,
                        (i) => setState(() => _typeIndex = i), t, isDark),
                    const SizedBox(height: AppSizes.s16),
                    _filterSection(
                        'Condition',
                        _conditionLabels,
                        _conditionIndex,
                        (i) => setState(() => _conditionIndex = i),
                        t,
                        isDark),
                    const SizedBox(height: AppSizes.s16),
                    Consumer<CategoryProvider>(
                      builder: (_, cp, __) {
                        final cats = ['All Categories', ...cp.categoryNames];
                        return _filterSection('Category', cats, _categoryIndex,
                            (i) => setState(() => _categoryIndex = i), t, isDark);
                      },
                    ),
                    const SizedBox(height: AppSizes.s16),
                    Text(
                      'Price Range',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Min',
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.textMuted),
                              prefixText: 'PKR ',
                              prefixStyle: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.textMuted),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : AppColors.bgSurface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusSm),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.s14,
                                vertical: AppSizes.s12,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s12),
                          child: Text('to',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.textMuted)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _maxCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Max',
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.textMuted),
                              prefixText: 'PKR ',
                              prefixStyle: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.textMuted),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : AppColors.bgSurface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusSm),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.s14,
                                vertical: AppSizes.s12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s24),
                  ],
                ),
              ),
            ),
            PremiumButton(
              label: 'Apply Filters',
              onPressed: () {
                final type = _typeIndex == 0 ? null : _types[_typeIndex];
                final condition = _conditionIndex == 0
                    ? null
                    : _conditions[_conditionIndex];
                final minP = double.tryParse(_minCtrl.text);
                final maxP = double.tryParse(_maxCtrl.text);
                widget.onApply(type, condition, minP, maxP);
                Navigator.pop(context);
              },
              style: PremiumButtonStyle.gradient,
              height: AppSizes.buttonLg,
              borderRadius: AppSizes.radiusMd,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterSection(String title, List<String> labels, int selected,
      ValueChanged<int> onSelect, ThemeData t, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.s10),
        Wrap(
          spacing: AppSizes.s8,
          runSpacing: AppSizes.s8,
          children: List.generate(labels.length, (i) {
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
                  labels[i],
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error / Shimmer states (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String searchQuery;
  final bool hasFilter;
  const _EmptyState({required this.searchQuery, required this.hasFilter});

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
                hasQuery ? Icons.search_off_rounded : Icons.menu_book_rounded,
                size: 44,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSizes.s20),
            Text(
              hasQuery ? 'No items found' : 'Nothing here yet',
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
                  : hasFilter
                      ? 'No items match your filters.\nTry adjusting them.'
                      : 'Be the first to list something!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
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
        final shimmer =
            theme.colorScheme.outline.withValues(alpha: _anim.value * 0.6);
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16, vertical: AppSizes.s8),
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
                _box(double.infinity, 200, shimmer, radius: AppSizes.radiusMd),
                const SizedBox(height: AppSizes.s14),
                _box(180, 14, shimmer),
                const SizedBox(height: AppSizes.s6),
                _box(120, 11, shimmer),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _box(double w, double h, Color color,
          {double radius = AppSizes.radiusSm}) =>
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
              child: const Icon(Icons.wifi_off_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: AppSizes.s16),
            Text(
              'Could not load listings',
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
                  fontSize: 14, color: AppColors.textMuted),
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
