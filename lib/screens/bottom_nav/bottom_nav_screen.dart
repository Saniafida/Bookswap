import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/animated_badge.dart';
import '../home/home_screen.dart';
import '../search/search_screen.dart';
import '../add_post/add_post_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => BottomNavScreenState();
}

class BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  void selectTab(int index) {
    _onTabSelected(index);
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    AddPostScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      final listingProvider =
          Provider.of<ListingProvider>(context, listen: false);
      listingProvider.fetchListings(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 600;
    final currentUserId =
        context.watch<AuthProvider>().currentUser?.id;
    final chatUnreadCount = currentUserId != null
        ? context.watch<ChatProvider>().totalUnreadFor(currentUserId)
        : 0;

    return Scaffold(
      extendBody: true,
      body: Row(
        children: [
          if (isWide) _buildSidebar(context, theme, isDark, chatUnreadCount),
          Expanded(
            child: Stack(
              children: List.generate(_screens.length, (index) {
                final isCurrent = index == _currentIndex;
                return IgnorePointer(
                  ignoring: !isCurrent,
                  child: AnimatedOpacity(
                    opacity: isCurrent ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _screens[index],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : _buildBottomBar(context, theme, isDark, chatUnreadCount),
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme, bool isDark, int chatUnreadCount) {
    return Container(
      height: 88,
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: EdgeInsets.fromLTRB(
          AppSizes.s20,
          0,
          AppSizes.s20,
          MediaQuery.of(context).padding.bottom > 0 ? 8 : AppSizes.s16,
        ),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double totalWidth = constraints.maxWidth;
                  final double tabWidth = totalWidth / 5;

                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        left: _currentIndex * tabWidth + (tabWidth - 64) / 2,
                        top: 6,
                        bottom: 6,
                        width: 64,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: _NavItem(
                              icon: Icons.home_outlined,
                              activeIcon: Icons.home_rounded,
                              label: AppStrings.navHome,
                              isSelected: _currentIndex == 0,
                              onTap: () => _onTabSelected(0),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              icon: Icons.search_outlined,
                              activeIcon: Icons.search_rounded,
                              label: AppStrings.navSearch,
                              isSelected: _currentIndex == 1,
                              onTap: () => _onTabSelected(1),
                            ),
                          ),
                          Expanded(
                            child: _AddButton(
                              isSelected: _currentIndex == 2,
                              onTap: () => _onTabSelected(2),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              icon: Icons.chat_bubble_outline_rounded,
                              activeIcon: Icons.chat_bubble_rounded,
                              label: AppStrings.navChat,
                              isSelected: _currentIndex == 3,
                              onTap: () => _onTabSelected(3),
                              unreadCount: chatUnreadCount,
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              icon: Icons.person_outline_rounded,
                              activeIcon: Icons.person_rounded,
                              label: AppStrings.navProfile,
                              isSelected: _currentIndex == 4,
                              onTap: () => _onTabSelected(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, ThemeData theme, bool isDark, int chatUnreadCount) {
    final user = context.watch<AuthProvider>().currentUser;
    final firstName = (user?.fullName ?? 'Reader').split(' ').first;

    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.bgCardDark : Colors.white).withValues(alpha: 0.88),
        border: Border(
          right: BorderSide(
            color: (isDark ? Colors.white : theme.colorScheme.primary)
                .withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.s16),
              child: Column(
                children: [
                  _buildSidebarLogo(theme),
                  const SizedBox(height: AppSizes.s20),
                  Container(
                    width: AppSizes.avatarMd,
                    height: AppSizes.avatarMd,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: user?.avatarUrl == null
                          ? AppColors.primaryGradient
                          : null,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: user?.avatarUrl != null
                          ? Image.network(
                              user!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _sidebarAvatarFallback(firstName, theme),
                            )
                          : _sidebarAvatarFallback(firstName, theme),
                    ),
                  ),
                  const SizedBox(height: AppSizes.s6),
                  Text(
                    firstName,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s20),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const double itemHeight = 72.0;
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutBack,
                              top: _currentIndex * itemHeight + 4,
                              left: 16,
                              right: 16,
                              height: 64,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                _SidebarNavItem(
                                  icon: Icons.home_outlined,
                                  activeIcon: Icons.home_rounded,
                                  label: AppStrings.navHome,
                                  isSelected: _currentIndex == 0,
                                  onTap: () => _onTabSelected(0),
                                  height: itemHeight,
                                ),
                                _SidebarNavItem(
                                  icon: Icons.search_outlined,
                                  activeIcon: Icons.search_rounded,
                                  label: AppStrings.navSearch,
                                  isSelected: _currentIndex == 1,
                                  onTap: () => _onTabSelected(1),
                                  height: itemHeight,
                                ),
                                _SidebarAddButton(
                                  isSelected: _currentIndex == 2,
                                  onTap: () => _onTabSelected(2),
                                  height: itemHeight,
                                ),
                                _SidebarNavItem(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  activeIcon: Icons.chat_bubble_rounded,
                                  label: AppStrings.navChat,
                                  isSelected: _currentIndex == 3,
                                  onTap: () => _onTabSelected(3),
                                  height: itemHeight,
                                  unreadCount: chatUnreadCount,
                                ),
                                _SidebarNavItem(
                                  icon: Icons.person_outline_rounded,
                                  activeIcon: Icons.person_rounded,
                                  label: AppStrings.navProfile,
                                  isSelected: _currentIndex == 4,
                                  onTap: () => _onTabSelected(4),
                                  height: itemHeight,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.s8),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings option tapped'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.settings_outlined,
                      size: AppSizes.iconMd,
                      color: isDark ? Colors.white54 : AppColors.textMuted,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarLogo(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.shopping_bag_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _sidebarAvatarFallback(String name, ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'R',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int unreadCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.unreadCount = 0,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTap: () {
        widget.onTap();
        _controller.forward().then((_) => _controller.reverse());
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isSelected ? widget.activeIcon : widget.icon,
                      key: ValueKey(isSelected),
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : theme.brightness == Brightness.dark
                              ? Colors.white54
                              : AppColors.textMuted,
                    ),
                  ),
                  if (widget.unreadCount > 0)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: AnimatedBadge(count: widget.unreadCount),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : theme.brightness == Brightness.dark
                          ? Colors.white54
                          : AppColors.textMuted,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _AddButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        _controller.forward().then((_) => _controller.reverse());
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: widget.isSelected ? 0.125 : 0.0,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 14,
                child: Text(
                  '',
                  style: GoogleFonts.poppins(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;
  final int unreadCount;

  const _SidebarNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.height,
    this.unreadCount = 0,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _SidebarNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTap: () {
        widget.onTap();
        _controller.forward().then((_) => _controller.reverse());
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isSelected ? widget.activeIcon : widget.icon,
                      key: ValueKey(isSelected),
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : theme.brightness == Brightness.dark
                              ? Colors.white54
                              : AppColors.textMuted,
                    ),
                  ),
                  if (widget.unreadCount > 0)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: AnimatedBadge(count: widget.unreadCount),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : theme.brightness == Brightness.dark
                          ? Colors.white54
                          : AppColors.textMuted,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarAddButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final double height;

  const _SidebarAddButton({
    required this.isSelected,
    required this.onTap,
    required this.height,
  });

  @override
  State<_SidebarAddButton> createState() => _SidebarAddButtonState();
}

class _SidebarAddButtonState extends State<_SidebarAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        _controller.forward().then((_) => _controller.reverse());
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: widget.isSelected ? 0.125 : 0.0,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 14,
                child: Text(
                  '',
                  style: GoogleFonts.poppins(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
