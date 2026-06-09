import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_routes.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_dialogs.dart';
import '../../widgets/premium_loading.dart';
import '../bottom_nav/bottom_nav_screen.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_posts_grid.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final currentUserId = auth.currentUser?.id;
    final targetUserId = widget.userId ?? currentUserId;
    if (targetUserId == null) return;

    final isOwnProfile = widget.userId == null || widget.userId == currentUserId;
    await profileProvider.loadProfileView(
      targetUserId: targetUserId,
      isOwnProfile: isOwnProfile,
    );
  }

  Future<void> _logout() async {
    await PremiumDialog.confirm(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      confirmColor: AppColors.error,
      onConfirm: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        await authProvider.signOut();
        profileProvider.reset();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
      },
    );
  }

  void _navigateToEditProfile() {
    Navigator.pushNamed(context, AppRoutes.editProfile).then((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final isOwnProfile = widget.userId == null || widget.userId == currentUserId;

    final profileProvider = Provider.of<ProfileProvider>(context);
    final UserModel? profile = profileProvider.profileFor(widget.userId, currentUserId);
    final isProfileLoading = profileProvider.isLoading && profile == null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: isOwnProfile
          ? AppBar(
              title: const Text(
                'My Profile',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit Profile',
                  onPressed: _navigateToEditProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  tooltip: 'Sign Out',
                  onPressed: _logout,
                ),
              ],
            )
          : CustomAppBar(
              title: profile?.fullName ?? 'Reader Profile',
              showBack: true,
            ),
      body: isProfileLoading
          ? const PageShimmer(itemCount: 3)
          : profile == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: ProfileHeader(
                          profile: profile,
                          isOwnProfile: isOwnProfile,
                          listingsCount: profileProvider.userPosts.length,
                        ),
                      ),
                      ProfilePostsGrid(
                        posts: profileProvider.userPosts,
                        isLoading: profileProvider.isLoadingPosts,
                        isOwnProfile: isOwnProfile,
                        onAddFirstBook: isOwnProfile
                            ? () {
                                final navState =
                                    context.findAncestorStateOfType<BottomNavScreenState>();
                                navState?.selectTab(2);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: AppSizes.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.error),
            ),
            SizedBox(height: AppSizes.s16),
            Text(
              'Could not load profile',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSizes.s8),
            Text(
              Provider.of<ProfileProvider>(context).errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white54 : AppColors.textMuted,
              ),
            ),
            SizedBox(height: AppSizes.s24),
            PremiumButton(
              label: 'Retry',
              style: PremiumButtonStyle.secondary,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: _loadData,
              height: AppSizes.buttonMd,
              width: 160,
            ),
          ],
        ),
      ),
    );
  }
}
