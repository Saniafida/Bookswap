import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/premium_loading.dart';
import '../../widgets/swaply_background.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/search_book_card.dart';
import 'widgets/search_empty_state.dart';
import 'widgets/search_filter_chips.dart';
import 'widgets/search_user_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final search = Provider.of<SearchProvider>(context, listen: false);
      search.initialize(currentUserId: auth.currentUser?.id);
      search.subscribeToListings();
      final cp = Provider.of<CategoryProvider>(context, listen: false);
      if (cp.status == CategoryStatus.initial) {
        cp.fetchCategories();
        cp.subscribeToCategories();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncControllerFromProvider(SearchProvider search) {
    if (_searchController.text != search.query) {
      _searchController.text = search.query;
      _searchController.selection = TextSelection.collapsed(
        offset: search.query.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final search = context.watch<SearchProvider>();

    _syncControllerFromProvider(search);

    return Scaffold(
      body: SwaplyBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark, search),
              _buildTabSwitcher(isDark, search),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: search.activeTab == SearchTab.items
                    ? const Column(
                        children: [
                          SizedBox(height: 12),
                          SearchFilterChips(),
                          SizedBox(height: 8),
                        ],
                      )
                    : const SizedBox(height: 12),
              ),
              _buildResultsBar(isDark, search),
              Expanded(child: _buildResults(isDark, search)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, SearchProvider search) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        AppStrings.discover,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      search.activeTab == SearchTab.items
                          ? AppStrings.findItems
                          : AppStrings.connectPeople,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (search.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SearchBarWidget(
            controller: _searchController,
            focusNode: _focusNode,
            hintText: search.activeTab == SearchTab.items
                ? AppStrings.searchHint
                : AppStrings.searchUsersHint,
            onChanged: search.updateQuery,
            onClear: () {
              _searchController.clear();
              search.clearQuery();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(bool isDark, SearchProvider search) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _TabButton(
                  label: AppStrings.searchItemsTab,
                  icon: Icons.shopping_bag_rounded,
                  isSelected: search.activeTab == SearchTab.items,
                  onTap: () => search.setActiveTab(SearchTab.items),
                ),
                _TabButton(
                  label: AppStrings.searchUsersTab,
                  icon: Icons.people_rounded,
                  isSelected: search.activeTab == SearchTab.users,
                  onTap: () => search.setActiveTab(SearchTab.users),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsBar(bool isDark, SearchProvider search) {
    if (search.isLoading && search.resultCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '${search.resultCount} result${search.resultCount == 1 ? '' : 's'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textMuted,
              ),
            ),
          ),
          if (search.hasActiveFilters &&
              search.activeTab == SearchTab.items)
            GestureDetector(
              onTap: search.clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s10,
                  vertical: AppSizes.s4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  AppStrings.clearFilters,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark, SearchProvider search) {
    if (search.isLoading && search.resultCount == 0) {
      return const PageShimmer(itemCount: 4);
    }

    if (search.activeTab == SearchTab.items) {
      if (search.listingResults.isEmpty) {
        return SearchEmptyState(
          tab: SearchTab.items,
          hasQuery: search.query.trim().isNotEmpty,
          hasFilters: search.hasActiveFilters,
          onClearFilters: search.clearFilters,
        );
      }
      return RefreshIndicator(
        onRefresh: () {
          final auth =
              Provider.of<AuthProvider>(context, listen: false);
          return search.refresh(
              currentUserId: auth.currentUser?.id);
        },
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: search.listingResults.length,
          itemBuilder: (_, index) =>
              SearchBookCard(listing: search.listingResults[index]),
        ),
      );
    }

    if (search.userResults.isEmpty) {
      return SearchEmptyState(
        tab: SearchTab.users,
        hasQuery: search.query.trim().isNotEmpty,
        hasFilters: false,
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        final auth =
            Provider.of<AuthProvider>(context, listen: false);
        return search.refresh(currentUserId: auth.currentUser?.id);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: search.userResults.length,
        itemBuilder: (_, index) =>
            SearchUserTile(user: search.userResults[index]),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
