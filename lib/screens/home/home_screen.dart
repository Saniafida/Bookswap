import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/listing_model.dart';
import '../../providers/home_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/announcement_banner.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/swaply_background.dart';
import '../search/widgets/search_book_card.dart';
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
                    SliverToBoxAdapter(
                      child: Consumer<AnnouncementProvider>(
                        builder: (_, ap, __) {
                          if (!ap.hasVisible) return const SizedBox.shrink();
                          final a = ap.topAnnouncement!;
                          return AnnouncementBanner(message: a.title);
                        },
                      ),
                    ),
  
                    SliverToBoxAdapter(
                      child: HomeHeader(
                        onSearchChanged: (q) =>
                            setState(() => _searchQuery = q),
                        onFilterPressed: () =>
                            _showFilterSheet(context, theme),
                      ),
                    ),
  
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.s12),
                        child: CategoryList(
                          onCategorySelected: (id) =>
                              setState(() => _selectedCategoryId = id),
                        ),
                      ),
                    ),
  
                    Consumer<HomeProvider>(
                      builder: (context, home, _) {
                        if (home.isLoading && home.status == HomeStatus.loading) {
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
                            _HomeSection('Featured', home.featuredListings),
                          if (home.popularListings.isNotEmpty)
                            _HomeSection('Popular', home.popularListings),
                          if (home.recentListings.isNotEmpty)
                            _HomeSection('Recently Added', home.recentListings),
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
  
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSizes.s20, AppSizes.s16, AppSizes.s20, AppSizes.s8),
                        child: Row(
                          children: [
                            Text(
                              'All Listings',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Consumer<ListingProvider>(
                              builder: (_, lp, __) {
                                if (lp.listings.isEmpty) return const SizedBox();
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
                          ],
                        ),
                      ),
                    ),
  
                    Consumer<ListingProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading &&
                            provider.listings.isEmpty) {
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _ShimmerCard(
                                  isDark: theme.brightness == Brightness.dark),
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
              color: Colors.white.withValues(alpha: 0.08),
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
                width: 180,
                margin: const EdgeInsets.only(right: AppSizes.s12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
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
      backgroundColor:
          isDark ? theme.colorScheme.surface : Colors.white,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.s20, AppSizes.s16, AppSizes.s20, AppSizes.s12),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: ShaderMask(
                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                  child: Text(
                    'See all',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
            physics: const BouncingScrollPhysics(),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSizes.s12),
                  child: SearchBookCard(listing: listing),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;
  final String? selectedType;
  final String? selectedCondition;
  final double? minPrice;
  final double? maxPrice;
  final void Function(
    String? type,
    String? condition,
    double? minPrice,
    double? maxPrice,
  ) onApply;

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
  final _conditionLabels = ['Any', 'Brand New', 'Like New', 'Good', 'Fair', 'Poor'];

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
                    _filterSection('Condition', _conditionLabels, _conditionIndex,
                        (i) => setState(() => _conditionIndex = i), t, isDark),
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
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
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
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                              prefixText: '\$ ',
                              prefixStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : AppColors.bgSurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
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
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
                          child: Text(
                            'to',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
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
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                              prefixText: '\$ ',
                              prefixStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : AppColors.bgSurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
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
                final condition =
                    _conditionIndex == 0 ? null : _conditions[_conditionIndex];
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
                  : hasFilter
                      ? 'No books match your filters.\nTry adjusting them.'
                      : 'Be the first to list a book!',
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
        final shimmer =
            theme.colorScheme.outline.withValues(alpha: _anim.value * 0.6);
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16, vertical: AppSizes.s8),
          child: Container(
            padding: AppSizes.cardPadding,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? theme.colorScheme.surface
                  : Colors.white,
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
                _box(double.infinity, 240, shimmer,
                    radius: AppSizes.radiusMd),
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
