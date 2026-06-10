// lib/admin/screens/users/admin_user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_user_provider.dart';
import '../../../data/models/listing_model.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_button.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserProvider>().loadUserDetail(widget.userId);
    });
  }

  void _confirmDelete(BuildContext context, String name, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const AdminConfirmDialog(title: 'Delete User Account', content: 'Are you sure you want to permanently delete this account? This action cannot be undone.', confirmLabel: 'Delete', isDangerous: true),
    );
    if (confirmed == true && mounted) {
      final success = await context.read<AdminUserProvider>().deleteUser(widget.userId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully')));
        Navigator.of(context).pop();
      }
    }
  }

  void _confirmBanToggle(BuildContext context, bool currentBanStatus, String name) async {
    final isBanning = !currentBanStatus;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AdminConfirmDialog(
        title: isBanning ? 'Ban User' : 'Unban User',
        content: isBanning ? 'Are you sure you want to ban $name? They will lose access to all Swaply services.' : 'Are you sure you want to unban $name?',
        confirmLabel: isBanning ? 'Ban' : 'Unban',
        isDangerous: isBanning,
      ),
    );
    if (confirmed == true && mounted) {
      final provider = context.read<AdminUserProvider>();
      final success = isBanning ? await provider.banUser(widget.userId) : await provider.unbanUser(widget.userId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User ${isBanning ? 'banned' : 'unbanned'} successfully')));
        provider.loadUserDetail(widget.userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgCardDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary), onPressed: () => Navigator.of(context).pop()),
        title: Text('User Profile Details', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Consumer<AdminUserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final user = provider.selectedUser;
          if (user == null) {
            return Center(child: Text('User details not found', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)));
          }
          final listings = provider.selectedUserListings;

          return SingleChildScrollView(
            padding: AppSizes.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(user, isDark),
                const SizedBox(height: AppSizes.s32),
                Row(
                  children: [
                    Container(width: 6, height: 20, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: AppSizes.s10),
                    Text('Listings Posted by User', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: AppSizes.s16),
                if (listings.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSizes.s32), child: Column(children: [
                    Icon(Icons.inventory_2_rounded, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
                    const SizedBox(height: AppSizes.s16),
                    Text('No listings posted by this user.', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted)),
                  ])))
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 3 : constraints.maxWidth > 400 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: AppSizes.s16, mainAxisSpacing: AppSizes.s16, childAspectRatio: crossAxisCount > 1 ? 0.72 : 1.2),
                        itemCount: listings.length,
                        itemBuilder: (context, index) => _buildListingGridItem(listings[index], isDark),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(dynamic user, bool isDark) {
    // user is UserModel
    return GlassCard(
      padding: AppSizes.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                backgroundColor: isDark ? AppColors.bgSurfaceDark : AppColors.primaryLight,
                child: user.avatarUrl == null
                    ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: AppSizes.s20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user.fullName, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                        if (user.isBanned) ...[
                          const SizedBox(width: AppSizes.s10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8, vertical: AppSizes.s3),
                            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.radiusXs), border: Border.all(color: AppColors.error.withValues(alpha: 0.25))),
                            child: Text('Banned', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSizes.s6),
                    Text(user.email, style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: AppSizes.s12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMuted, size: AppSizes.iconXs),
                        const SizedBox(width: AppSizes.s4),
                        Text('Joined: ${user.createdAt.toLocal().toString().split(' ')[0]}', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                        const SizedBox(width: AppSizes.s16),
                        Icon(Icons.sync_alt_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMuted, size: AppSizes.iconXs),
                        const SizedBox(width: AppSizes.s4),
                        Text('Swaps: ${user.swapCount}', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSizes.s20),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.s12),
            Text('Biography', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSizes.s6),
            Text(user.bio!, style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13, height: 1.4)),
          ],
          const SizedBox(height: AppSizes.s24),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.s16),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: user.isBanned ? 'Unban User Account' : 'Ban User Account',
                  icon: Icon(user.isBanned ? Icons.check_circle_outline_rounded : Icons.block_rounded, size: 18),
                  style: PremiumButtonStyle.secondary,
                  color: user.isBanned ? AppColors.success : AppColors.error,
                  textColor: user.isBanned ? AppColors.success : AppColors.error,
                  height: AppSizes.buttonMd,
                  onPressed: () => _confirmBanToggle(context, user.isBanned, user.fullName),
                ),
              ),
              const SizedBox(width: AppSizes.s16),
              Expanded(
                child: PremiumButton(
                  label: 'Delete Account',
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  color: AppColors.error,
                  height: AppSizes.buttonMd,
                  onPressed: () => _confirmDelete(context, user.fullName, user.email),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingGridItem(ListingModel listing, bool isDark) {
    final thumbnailUrl = listing.images.isNotEmpty ? listing.images.first.url : null;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: isDark ? AppColors.bgSurfaceDark : AppColors.bgSurface,
              child: thumbnailUrl != null
                  ? Image.network(thumbnailUrl, fit: BoxFit.cover)
                  : Center(child: Icon(Icons.inventory_2_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMuted, size: 36)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSizes.s2),
                Text(listing.listingTypeLabel, style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSizes.s8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s6, vertical: AppSizes.s2),
                      decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppSizes.radiusXs)),
                      child: Text(listing.listingTypeLabel.toUpperCase(), style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w700)),
                    ),
                    if (listing.price != null && listing.price! > 0)
                      Text('\$${listing.price!.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
