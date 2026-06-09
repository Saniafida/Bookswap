import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../providers/auth_provider.dart';
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
      duration: const Duration(milliseconds: 400),
    );
    _bellAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.elasticIn),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _bellController.repeat(reverse: true);
      Future.delayed(const Duration(seconds: 1), () {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final firstName = (user?.fullName ?? 'Reader').split(' ').first;
    final greeting = _getGreeting();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s20, AppSizes.s20, AppSizes.s20, AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  final nav = context
                      .findAncestorStateOfType<BottomNavScreenState>();
                  nav?.selectTab(4);
                },
                child: Hero(
                  tag: 'user_avatar',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: user?.avatarUrl == null
                          ? AppColors.primaryGradient
                          : null,
                      border: Border.all(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.25),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user?.avatarUrl != null
                          ? Image.network(
                              user!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarFallback(firstName, theme),
                            )
                          : _avatarFallback(firstName, theme),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s2),
                    Text(
                      'Hey, $firstName',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              RotationTransition(
                turns: _bellAnimation,
                child: _NotificationBell(isDark: isDark, theme: theme),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s20),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark
                          ? theme.colorScheme.surface
                          : Colors.white)
                      .withValues(alpha: 0.9),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: _isFocused
                        ? theme.colorScheme.primary
                            .withValues(alpha: 0.5)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : AppColors.border),
                    width: _isFocused ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isFocused
                          ? theme.colorScheme.primary
                              .withValues(alpha: 0.10)
                          : (isDark
                              ? Colors.black.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.03)),
                      blurRadius: _isFocused ? 20 : 8,
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
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search books, authors...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Colors.white38
                                : AppColors.textMuted,
                          ),
                          prefixIcon: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.search_rounded,
                              color: _isFocused
                                  ? theme.colorScheme.primary
                                  : (isDark
                                      ? Colors.white38
                                      : AppColors.textMuted),
                              size: AppSizes.iconMd,
                            ),
                          ),
                          filled: false,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: AppSizes.s20,
                            vertical: AppSizes.s16,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onFilterPressed,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(
                                AppSizes.radiusMd),
                            bottomRight: Radius.circular(
                                AppSizes.radiusMd),
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: theme.colorScheme.primary,
                          size: AppSizes.iconMd,
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

  Widget _avatarFallback(String name, ThemeData theme) {
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _NotificationBell extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _NotificationBell({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new notifications'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: (isDark ? theme.colorScheme.surface : Colors.white)
              .withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              size: AppSizes.iconMd,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? theme.colorScheme.surface
                        : Colors.white,
                    width: 1.5,
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
