// lib/admin/screens/users/admin_users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_user_provider.dart';
import 'package:swaply/models/user_model.dart';
import 'package:swaply/core/enums/user_role.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _bannedFilter = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserProvider>().fetchUsers(refresh: true);
    });
  }

  void _confirmDelete(BuildContext context, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const AdminConfirmDialog(
        title: 'Delete User Account',
        content: 'Are you sure you want to permanently delete this account? This action is irreversible.',
        confirmLabel: 'Delete',
        isDangerous: true,
      ),
    );
    if (confirmed == true && mounted) {
      final success = await context.read<AdminUserProvider>().deleteUser(user.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully')));
      }
    }
  }

  void _confirmBanToggle(BuildContext context, UserModel user) async {
    final isBanning = !user.isBanned;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AdminConfirmDialog(
        title: isBanning ? 'Ban User' : 'Unban User',
        content: isBanning ? 'Are you sure you want to ban ${user.fullName}? They will be restricted from accessing their account.' : 'Are you sure you want to unban ${user.fullName}?',
        confirmLabel: isBanning ? 'Ban' : 'Unban',
        isDangerous: isBanning,
      ),
    );
    if (confirmed == true && mounted) {
      final provider = context.read<AdminUserProvider>();
      final success = isBanning ? await provider.banUser(user.id) : await provider.unbanUser(user.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User ${isBanning ? 'banned' : 'unbanned'} successfully')));
      }
    }
  }

  void _changeUserRole(BuildContext context, UserModel user, UserRole role) async {
    if (user.role == role) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AdminConfirmDialog(
        title: 'Change User Role',
        content: 'Are you sure you want to change the role of ${user.fullName} to ${role.name.toUpperCase()}?',
        confirmLabel: 'Change',
      ),
    );
    if (confirmed == true && mounted) {
      final success = await context.read<AdminUserProvider>().changeRole(user.id, role);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated to ${role.name}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<AdminUserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: AppSizes.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark, userProvider),
            const SizedBox(height: AppSizes.s24),
            Expanded(child: _buildUsersGrid(userProvider, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, AdminUserProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final filterBtn = GestureDetector(
          onTap: () {
            setState(() => _bannedFilter = !_bannedFilter);
            provider.setFilter(bannedOnly: _bannedFilter);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s14, vertical: AppSizes.s8),
            decoration: BoxDecoration(
              color: _bannedFilter ? AppColors.error.withValues(alpha: 0.1) : (isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(color: _bannedFilter ? AppColors.error.withValues(alpha: 0.4) : (isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5))),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_bannedFilter ? Icons.block_rounded : Icons.people_outline_rounded, size: AppSizes.iconSm, color: _bannedFilter ? AppColors.error : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
                const SizedBox(width: AppSizes.s6),
                Text(_bannedFilter ? 'Banned Only' : 'All Users', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _bannedFilter ? AppColors.error : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary))),
              ],
            ),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User Management', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: AppSizes.s4),
              Text('View, search, ban/unban, and modify roles of platform accounts.', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: AppSizes.s12),
              Row(children: [filterBtn, const SizedBox(width: AppSizes.s8), Expanded(child: AdminSearchBar(hintText: 'Search users...', onChanged: (v) => provider.setSearch(v)))]),
            ],
          );
        }
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Management', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: AppSizes.s4),
                Text('View, search, ban/unban, and modify roles of platform accounts.', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const Spacer(),
            SizedBox(width: 220, child: AdminSearchBar(hintText: 'Search users...', onChanged: (v) => provider.setSearch(v))),
            const SizedBox(width: AppSizes.s12),
            filterBtn,
          ],
        );
      },
    );
  }

  Widget _buildUsersGrid(AdminUserProvider provider, bool isDark) {
    if (provider.isLoading && provider.users.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (provider.users.isEmpty) {
      return AdminEmptyState(title: 'No users found', subtitle: 'No accounts match your current filters.', icon: Icons.people_outline_rounded);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        final ratio = crossAxisCount == 1 ? 1.8 : 1.35;

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: AppSizes.s16, mainAxisSpacing: AppSizes.s16, childAspectRatio: ratio),
                itemCount: provider.users.length,
                itemBuilder: (context, index) => _buildUserCard(provider.users[index], isDark),
              ),
            ),
            if (provider.hasMore) ...[
              const SizedBox(height: AppSizes.s16),
              TextButton(
                onPressed: () => provider.fetchUsers(),
                child: provider.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : Text('Load More Users', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user, bool isDark) {
    return GlassCard(
      padding: AppSizes.cardPaddingCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                backgroundColor: isDark ? AppColors.bgSurfaceDark : AppColors.primaryLight,
                child: user.avatarUrl == null
                    ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14))
                    : null,
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSizes.s2),
                    Text(user.email, style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _buildStatusBadge(user.isBanned ? 'Banned' : 'Active', user.isBanned ? AppColors.error : AppColors.success),
              const SizedBox(width: AppSizes.s8),
              _buildStatusBadge(user.role.badgeLabel, user.isAdmin ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconBtn(Icons.visibility_rounded, AppColors.primary, 'View Profile', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminUserDetailScreen(userId: user.id)))),
              _buildIconBtn(Icons.manage_accounts_rounded, isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, 'Change Role', null, popupMenu: UserRole.values.map((r) => PopupMenuItem<UserRole>(value: r, child: Text(r.name.toUpperCase(), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)))).toList(), onSelected: (role) => _changeUserRole(context, user, role)),
              _buildIconBtn(user.isBanned ? Icons.check_circle_outline_rounded : Icons.block_rounded, user.isBanned ? AppColors.success : AppColors.error, user.isBanned ? 'Unban' : 'Ban', () => _confirmBanToggle(context, user)),
              _buildIconBtn(Icons.delete_outline_rounded, AppColors.error, 'Delete', () => _confirmDelete(context, user)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8, vertical: AppSizes.s3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.radiusXs), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Text(label, style: GoogleFonts.poppins(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, String tooltip, VoidCallback? onPressed, {List<PopupMenuItem>? popupMenu, Function(dynamic)? onSelected}) {
    if (popupMenu != null) {
      return PopupMenuButton(
        icon: Icon(icon, color: color, size: AppSizes.iconSm),
        tooltip: tooltip,
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
        onSelected: onSelected,
        itemBuilder: (context) => popupMenu,
      );
    }
    return IconButton(icon: Icon(icon, color: color, size: AppSizes.iconSm), tooltip: tooltip, constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: onPressed);
  }
}
