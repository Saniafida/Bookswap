// lib/admin/screens/admin_shell_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/permission_helper.dart';
import '../providers/admin_user_provider.dart';
import '../providers/admin_book_provider.dart';
import '../../widgets/premium_button.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'users/admin_users_screen.dart';
import 'books/admin_books_screen.dart';
import 'categories/admin_categories_screen.dart';
import 'reports/admin_reports_screen.dart';
import 'announcements/admin_announcements_screen.dart';
import 'settings/admin_settings_screen.dart';
import 'analytics/admin_analytics_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _selectedIndex = 0;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.people_alt_rounded, label: 'Users'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Listings'),
    _NavItem(icon: Icons.category_rounded, label: 'Categories'),
    _NavItem(icon: Icons.flag_rounded, label: 'Reports'),
    _NavItem(icon: Icons.campaign_rounded, label: 'Announcements'),
    _NavItem(icon: Icons.analytics_rounded, label: 'Analytics'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminBooksScreen(),
    AdminCategoriesScreen(),
    AdminReportsScreen(),
    AdminAnnouncementsScreen(),
    AdminAnalyticsScreen(),
    AdminSettingsScreen(),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int? _getBottomNavIndex(int index) {
    return switch (index) {
      0 => 0,
      1 => 1,
      2 => 2,
      3 => 3,
      7 => 4,
      _ => null,
    };
  }

  void _onBottomNavSelect(int index) {
    final target = switch (index) {
      0 => 0,
      1 => 1,
      2 => 2,
      3 => 3,
      4 => 7,
      _ => 0,
    };
    setState(() => _selectedIndex = target);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!PermissionHelper.canAccessAdmin(auth.currentRole)) {
      return const _AccessDenied();
    }

    final isMobile = MediaQuery.of(context).size.width < AppSizes.tabletBreakpoint;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sidebar = _AdminSidebar(
      items: _items,
      selectedIndex: _selectedIndex,
      onSelect: (i) {
        setState(() => _selectedIndex = i);
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
        }
      },
      adminName: auth.currentUser?.fullName ?? 'Admin',
      adminEmail: auth.currentUser?.email ?? '',
      avatarUrl: auth.currentUser?.avatarUrl,
      onLogout: () async {
        await auth.signOut();
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      },
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      drawer: isMobile
          ? Drawer(
              width: 280,
              backgroundColor: isDark ? AppColors.bgCardDark : Colors.white,
              child: sidebar,
            )
          : null,
      bottomNavigationBar: isMobile
          ? _buildBottomNav(isDark)
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile) sidebar,
            Expanded(
              child: Column(
                children: [
                  _AdminHeader(
                    selectedIndex: _selectedIndex,
                    isMobile: isMobile,
                    onMenuPressed: isMobile
                        ? () => _scaffoldKey.currentState?.openDrawer()
                        : null,
                    adminName: auth.currentUser?.fullName ?? 'Admin',
                    adminEmail: auth.currentUser?.email ?? '',
                    avatarUrl: auth.currentUser?.avatarUrl,
                    onSelectScreen: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    onLogout: () async {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                      }
                    },
                  ),
                  Expanded(
                    child: _screens[_selectedIndex],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark.withValues(alpha: 0.4) : AppColors.border.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _MobileNavItem(icon: Icons.dashboard_rounded, label: 'Home', isSelected: _getBottomNavIndex(_selectedIndex) == 0, onTap: () => _onBottomNavSelect(0)),
          _MobileNavItem(icon: Icons.people_alt_rounded, label: 'Users', isSelected: _getBottomNavIndex(_selectedIndex) == 1, onTap: () => _onBottomNavSelect(1)),
          _MobileNavItem(icon: Icons.inventory_2_rounded, label: 'Listings', isSelected: _getBottomNavIndex(_selectedIndex) == 2, onTap: () => _onBottomNavSelect(2)),
          _MobileNavItem(icon: Icons.category_rounded, label: 'Cats', isSelected: _getBottomNavIndex(_selectedIndex) == 3, onTap: () => _onBottomNavSelect(3)),
          _MobileNavItem(icon: Icons.settings_rounded, label: 'Settings', isSelected: _getBottomNavIndex(_selectedIndex) == 4, onTap: () => _onBottomNavSelect(4)),
        ],
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobileNavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconMd, color: isSelected ? AppColors.primary : (isDark ? AppColors.textMutedDark : AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : (isDark ? AppColors.textMutedDark : AppColors.textMuted))),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 16, height: 2,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(1)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String adminName;
  final String adminEmail;
  final String? avatarUrl;

  final VoidCallback onLogout;

  const _AdminSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.adminName,
    required this.adminEmail,
    required this.onLogout,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        border: Border(
          right: BorderSide(color: isDark ? AppColors.borderDark.withValues(alpha: 0.4) : AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        children: [
          _buildLogo(),
          Expanded(child: _buildNavList(isDark)),
          _buildSidebarFooter(context),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSizes.s24, AppSizes.s48, AppSizes.s24, AppSizes.s20),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSizes.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Swaply', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.5)),
              Text('Admin Console', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.secondary, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12, vertical: AppSizes.s8),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildNavTile(i, isDark),
    );
  }

  Widget _buildNavTile(int index, bool isDark) {
    final item = items[index];
    final isSelected = index == selectedIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(index),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s14, vertical: AppSizes.s12),
            decoration: BoxDecoration(
              color: isSelected ? (isDark ? AppColors.bgSurfaceDark : AppColors.primaryLight.withValues(alpha: 0.5)) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.15)) : null,
            ),
            child: Row(
              children: [
                Icon(item.icon, size: AppSizes.iconMd, color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
                const SizedBox(width: AppSizes.s12),
                Text(item.label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary))),
                const Spacer(),
                if (isSelected)
                  Container(width: 3, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: AppSizes.s16),
          SizedBox(
            width: double.infinity,
            child: PremiumButton(
              label: 'Back to User App',
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              style: PremiumButtonStyle.glass,
              height: AppSizes.buttonMd,
              onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.bottomNav),
            ),
          ),
          const SizedBox(height: AppSizes.s10),
          SizedBox(
            width: double.infinity,
            child: PremiumButton(
              label: 'Sign Out',
              icon: const Icon(Icons.logout_rounded, size: 16),
              style: PremiumButtonStyle.secondary,
              height: AppSizes.buttonMd,
              onPressed: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final int selectedIndex;
  final bool isMobile;
  final VoidCallback? onMenuPressed;
  final String adminName;
  final String adminEmail;
  final String? avatarUrl;
  final ValueChanged<int> onSelectScreen;
  final VoidCallback onLogout;

  const _AdminHeader({
    required this.selectedIndex,
    required this.isMobile,
    this.onMenuPressed,
    required this.adminName,
    required this.adminEmail,
    required this.onSelectScreen,
    required this.onLogout,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 72,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark.withValues(alpha: 0.4) : AppColors.border.withValues(alpha: 0.6))),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSizes.s12 : AppSizes.s24),
      child: isMobile
          ? Row(
              children: [
                if (onMenuPressed != null) ...[
                  IconButton(icon: Icon(Icons.menu_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary), onPressed: onMenuPressed),
                  const SizedBox(width: AppSizes.s8),
                ],
                Expanded(child: _buildSearchBar(context)),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: _buildSearchBar(context),
                    ),
                  ),
                ),
                _buildQuickActions(context),
                const SizedBox(width: AppSizes.s12),
                _buildNotifications(context),
                const SizedBox(width: AppSizes.s12),
                _buildProfileMenu(context),
              ],
            ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showSearch = selectedIndex == 1 || selectedIndex == 2;
    if (!showSearch) return const SizedBox.shrink();

    String hint = 'Search...';
    if (selectedIndex == 1) hint = 'Search users by name/email...';
    if (selectedIndex == 2) hint = 'Search listings by title...';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
      ),
      child: TextField(
        onChanged: (val) {
          if (selectedIndex == 1) {
            context.read<AdminUserProvider>().setSearch(val);
          } else if (selectedIndex == 2) {
            context.read<AdminBookProvider>().setSearch(val);
          }
        },
        style: GoogleFonts.poppins(fontSize: 13, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w400),
          prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMuted, size: AppSizes.iconSm),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Quick Actions',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12, vertical: AppSizes.s8),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            const SizedBox(width: AppSizes.s4),
            Text('Quick Action', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 1, child: Row(children: [Icon(Icons.category_rounded, size: 16, color: AppColors.textSecondary), SizedBox(width: 8), Text('Add Category', style: TextStyle(fontFamily: 'Poppins'))])),
        const PopupMenuItem(value: 2, child: Row(children: [Icon(Icons.campaign_rounded, size: 16, color: AppColors.textSecondary), SizedBox(width: 8), Text('Create Announcement', style: TextStyle(fontFamily: 'Poppins'))])),
        const PopupMenuItem(value: 3, child: Row(children: [Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.textSecondary), SizedBox(width: 8), Text('Manage Listings', style: TextStyle(fontFamily: 'Poppins'))])),
      ],
      onSelected: (val) {
        if (val == 1) onSelectScreen(3);
        else if (val == 2) onSelectScreen(5);
        else if (val == 3) onSelectScreen(2);
      },
    );
  }

  Widget _buildNotifications(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Notifications',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface, size: AppSizes.iconMd),
          Positioned(right: -2, top: -2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle))),
        ],
      ),
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      itemBuilder: (context) => [
        const PopupMenuItem(enabled: false, child: Text('Recent Notifications', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
        const PopupMenuDivider(),
        const PopupMenuItem(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('System Online', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)), Text('All server metrics look healthy.', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary, fontSize: 11))])),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<int>(
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            backgroundColor: isDark ? AppColors.bgSurfaceDark : AppColors.primaryLight,
            child: avatarUrl == null
                ? Text(adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14))
                : null,
          ),
          if (!isMobile) ...[
            const SizedBox(width: AppSizes.s8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(adminName, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Administrator', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(width: AppSizes.s4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          ],
        ],
      ),
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      itemBuilder: (context) => [
        PopupMenuItem(value: 1, child: Row(children: [const Icon(Icons.settings_outlined, size: 16, color: AppColors.textSecondary), const SizedBox(width: 8), const Text('Account Settings', style: TextStyle(fontFamily: 'Poppins'))])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 2, child: Row(children: [const Icon(Icons.logout_rounded, size: 16, color: AppColors.error), const SizedBox(width: 8), const Text('Sign Out', style: TextStyle(fontFamily: 'Poppins', color: AppColors.error))])),
      ],
      onSelected: (val) {
        if (val == 1) onSelectScreen(7);
        else if (val == 2) onLogout();
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: Center(
        child: Padding(
          padding: AppSizes.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s20),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: AppColors.error.withValues(alpha: 0.2))),
                child: const Icon(Icons.shield_rounded, size: 48, color: AppColors.error),
              ),
              const SizedBox(height: AppSizes.s24),
              Text('Access Denied', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
              const SizedBox(height: AppSizes.s8),
              Text('This area is restricted to admins only.', style: GoogleFonts.poppins(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              const SizedBox(height: AppSizes.s32),
              PremiumButton(
                label: 'Go Back Home',
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                width: 200,
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.bottomNav),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
