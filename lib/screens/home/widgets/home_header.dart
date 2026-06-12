import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../bottom_nav/bottom_nav_screen.dart';

class HomeHeader extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterPressed;

  const HomeHeader({
    super.key,
    required this.onSearchChanged,
    required this.onFilterPressed,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bellAnimation = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.elasticIn),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _bellController.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _bellController.stop();
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _bellController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '👋';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final firstName = (user?.fullName ?? 'Friend').split(' ').first;
    final greeting = _getGreeting();
    final emoji = _getGreetingEmoji();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s20, AppSizes.s16, AppSizes.s20, AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar: Hamburger | Notification + Avatar ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hamburger menu
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                    ),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),

              const Spacer(),

              // Notification bell
              RotationTransition(
                turns: _bellAnimation,
                child: _NotificationBell(),
              ),

              const SizedBox(width: AppSizes.s10),

              // Avatar
              GestureDetector(
                onTap: () {
                  final nav = context
                      .findAncestorStateOfType<BottomNavScreenState>();
                  nav?.selectTab(4);
                },
                child: Hero(
                  tag: 'user_avatar',
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: user?.avatarUrl == null
                          ? AppColors.primaryGradient
                          : null,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.20),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user?.avatarUrl != null
                          ? Image.network(
                              user!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarFallback(firstName),
                            )
                          : _avatarFallback(firstName),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.s16),

          // ── Greeting ───────────────────────────────────────────────────
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$greeting, $firstName ',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'What are you looking for today?',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: AppSizes.s16),

          // ── Search Bar ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: _isFocused ? 0.97 : 0.90),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: _isFocused
                        ? AppColors.primary.withValues(alpha: 0.50)
                        : AppColors.border.withValues(alpha: 0.70),
                    width: _isFocused ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isFocused
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: _isFocused ? 20 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        focusNode: _focusNode,
                        onChanged: widget.onSearchChanged,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search anything on Swaply...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _isFocused
                                ? AppColors.primary
                                : AppColors.textMuted,
                            size: 22,
                          ),
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.s16,
                            vertical: AppSizes.s14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),

                    // Filter button
                    GestureDetector(
                      onTap: widget.onFilterPressed,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(AppSizes.radiusMd),
                            bottomRight: Radius.circular(AppSizes.radiusMd),
                          ),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotificationProvider>().unreadCount;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xFFFFE8F0), // Soft pink circular background
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded, // Outline bell matching screenshot
              color: AppColors.textPrimary,
              size: 24,
            ),
            if (count > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error, // Red badge
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
