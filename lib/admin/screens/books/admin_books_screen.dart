// lib/admin/screens/books/admin_books_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_book_provider.dart';
import '../../providers/admin_category_provider.dart';
import '../../../data/models/listing_model.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_button.dart';
import 'admin_book_edit_screen.dart';
import 'admin_add_book_screen.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBookProvider>().fetchListings(refresh: true);
      context.read<AdminCategoryProvider>().fetchCategories();
    });
  }

  void _confirmDelete(BuildContext context, ListingModel listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AdminConfirmDialog(
        title: 'Delete Listing',
        content: 'Are you sure you want to permanently delete the listing "${listing.title}"? This listing will be removed from all users.',
        confirmLabel: 'Delete',
        isDangerous: true,
      ),
    );
    if (confirmed == true && mounted) {
      final success = await context.read<AdminBookProvider>().deleteListing(listing.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing deleted successfully')));
      }
    }
  }

  void _toggleFeatured(BuildContext context, ListingModel listing) async {
    final newFeatured = !listing.isFeatured;
    final success = await context.read<AdminBookProvider>().setFeatured(listing.id, featured: newFeatured);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing is now ${newFeatured ? 'featured' : 'unfeatured'}')));
    }
  }

  void _toggleApproval(BuildContext context, ListingModel listing) async {
    final newApproved = !listing.isApproved;
    final success = await context.read<AdminBookProvider>().setApproval(listing.id, approved: newApproved);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing ${newApproved ? 'approved' : 'unapproved'}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = context.watch<AdminBookProvider>();
    final categoryProvider = context.watch<AdminCategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: PremiumButton(
        label: 'Add Listing',
        icon: const Icon(Icons.add_rounded, size: 18),
        style: PremiumButtonStyle.gradient,
        width: 160,
        height: AppSizes.buttonMd,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminAddBookScreen())),
      ),
      body: Padding(
        padding: AppSizes.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark, listingProvider, categoryProvider),
            const SizedBox(height: AppSizes.s24),
            Expanded(child: _buildListingsGrid(listingProvider, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, AdminBookProvider listingProvider, AdminCategoryProvider categoryProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final filterDropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedCategory,
              isExpanded: true,
              hint: Text('All Categories', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              dropdownColor: isDark ? AppColors.bgCardDark : Colors.white,
              style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              icon: Icon(Icons.arrow_drop_down_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              onChanged: (val) {
                setState(() => _selectedCategory = val);
                listingProvider.setCategory(val);
              },
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All Categories', overflow: TextOverflow.ellipsis)),
                ...categoryProvider.categories.map((c) => DropdownMenuItem<String?>(value: c.name, child: Text(c.name, overflow: TextOverflow.ellipsis))),
              ],
            ),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Listing Management', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: AppSizes.s4),
              Text('Inspect listing details, toggle featured/approval status, or prune listings.', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: AppSizes.s12),
              SizedBox(width: double.infinity, child: filterDropdown),
              const SizedBox(height: AppSizes.s8),
              SizedBox(width: double.infinity, height: 44, child: AdminSearchBar(hintText: 'Search listings...', onChanged: (v) => listingProvider.setSearch(v))),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Listing Management', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: AppSizes.s4),
                Text('Inspect listing details, toggle featured/approval status, or prune listings.', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            Row(children: [
              SizedBox(width: 200, child: AdminSearchBar(hintText: 'Search listings...', onChanged: (v) => listingProvider.setSearch(v))),
              const SizedBox(width: AppSizes.s12),
              filterDropdown,
            ]),
          ],
        );
      },
    );
  }

  Widget _buildListingsGrid(AdminBookProvider provider, bool isDark) {
    if (provider.isLoading && provider.listings.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (provider.error != null) {
      return AdminEmptyState(title: 'Error loading listings', subtitle: provider.error!, icon: Icons.error_outline_rounded);
    }
    if (provider.listings.isEmpty) {
      return AdminEmptyState(title: 'No listings found', subtitle: 'No listings match your current filters.', icon: Icons.inventory_2_rounded);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        final ratio = isMobile ? 1.8 : 0.75;

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: AppSizes.s16, mainAxisSpacing: AppSizes.s16, childAspectRatio: ratio),
                itemCount: provider.listings.length,
                itemBuilder: (context, index) => _buildListingCard(provider.listings[index], isDark, isMobile: isMobile),
              ),
            ),
            if (provider.hasMore) ...[
              const SizedBox(height: AppSizes.s16),
              TextButton(
                onPressed: () => provider.fetchListings(),
                child: provider.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : Text('Load More Listings', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildListingCard(ListingModel listing, bool isDark, {bool isMobile = false}) {
    final thumbnailUrl = listing.images.isNotEmpty ? listing.images.first.url : null;

    if (isMobile) {
      return GlassCard(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              width: 100, height: double.infinity,
              color: isDark ? AppColors.bgSurfaceDark : AppColors.bgSurface,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumbnailUrl != null ? Image.network(thumbnailUrl, fit: BoxFit.cover) : Center(child: Icon(Icons.inventory_2_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMuted, size: 32)),
                  if (listing.isFeatured)
                    Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(AppSizes.radiusXs)), child: const Icon(Icons.star_rounded, color: Colors.white, size: 10))),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSizes.s2),
                    Text(listing.conditionLabel, style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSizes.s8),
                    Wrap(spacing: 4, runSpacing: 4, children: [
                      if (listing.categoryName != null) _buildTag(listing.categoryName!, AppColors.primary),
                      _buildTag(listing.listingTypeLabel, AppColors.secondary),
                      _buildTag(listing.status.toUpperCase(), listing.isActive ? AppColors.success : AppColors.error),
                      if (listing.price != null && listing.price! > 0) _buildTag('\$${listing.price!.toStringAsFixed(2)}', AppColors.success),
                    ]),
                    const Spacer(),
                    if (listing.ownerName != null)
                      Text('Owner: ${listing.ownerName}', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            _buildActions(listing),
          ],
        ),
      );
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: isDark ? AppColors.bgSurfaceDark : AppColors.bgSurface,
                  child: thumbnailUrl != null ? Image.network(thumbnailUrl, fit: BoxFit.cover) : Center(child: Icon(Icons.inventory_2_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMuted, size: 40)),
                ),
                if (listing.isFeatured)
                  Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(AppSizes.radiusXs)), child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: Colors.white, size: 10),
                    const SizedBox(width: 2),
                    Text('FEATURED', style: GoogleFonts.poppins(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                  ]))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSizes.s2),
                  Text(listing.conditionLabel, style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSizes.s8),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    if (listing.categoryName != null) _buildTag(listing.categoryName!, AppColors.primary),
                    _buildTag(listing.listingTypeLabel, AppColors.secondary),
                    _buildTag(listing.status.toUpperCase(), listing.isActive ? AppColors.success : AppColors.error),
                    if (listing.price != null && listing.price! > 0) _buildTag('\$${listing.price!.toStringAsFixed(2)}', AppColors.success),
                  ]),
                  if (listing.ownerName != null) ...[
                    const SizedBox(height: AppSizes.s8),
                    Text('Owner: ${listing.ownerName}', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                  const Spacer(),
                  const Divider(height: 1),
                  const SizedBox(height: AppSizes.s4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(icon: Icon(listing.isFeatured ? Icons.star_rounded : Icons.star_outline_rounded, color: listing.isFeatured ? AppColors.warning : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary), size: AppSizes.iconSm), tooltip: listing.isFeatured ? 'Unfeature' : 'Feature', constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: () => _toggleFeatured(context, listing)),
                      IconButton(icon: Icon(listing.isApproved ? Icons.verified_rounded : Icons.verified_outlined, color: listing.isApproved ? AppColors.success : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary), size: AppSizes.iconSm), tooltip: listing.isApproved ? 'Revoke Approval' : 'Approve', constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: () => _toggleApproval(context, listing)),
                      IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: AppSizes.iconSm), tooltip: 'Edit', constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminBookEditScreen(listing: listing)))),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: AppSizes.iconSm), tooltip: 'Delete', constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: () => _confirmDelete(context, listing)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ListingModel listing) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(listing.isFeatured ? Icons.star_rounded : Icons.star_outline_rounded, color: listing.isFeatured ? AppColors.warning : AppColors.textSecondary, size: AppSizes.iconSm), tooltip: listing.isFeatured ? 'Unfeature' : 'Feature', constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: () => _toggleFeatured(context, listing)),
          IconButton(icon: Icon(listing.isApproved ? Icons.verified_rounded : Icons.verified_outlined, color: listing.isApproved ? AppColors.success : AppColors.textSecondary, size: AppSizes.iconSm), tooltip: listing.isApproved ? 'Revoke Approval' : 'Approve', constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: () => _toggleApproval(context, listing)),
          IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: AppSizes.iconSm), tooltip: 'Edit', constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminBookEditScreen(listing: listing)))),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: AppSizes.iconSm), tooltip: 'Delete', constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: () => _confirmDelete(context, listing)),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s6, vertical: AppSizes.s2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSizes.radiusXs), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label, style: GoogleFonts.poppins(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}
