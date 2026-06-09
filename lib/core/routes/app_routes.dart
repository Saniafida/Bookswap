import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/bottom_nav/bottom_nav_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/add_post/add_post_screen.dart';
import '../../screens/post_details/post_details_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../admin/screens/admin_shell_screen.dart';
import '../../providers/auth_provider.dart';
import 'route_guard.dart';

/// Named route constants — never use raw strings for navigation.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String bottomNav = '/home';
  static const String home = '/home/feed';
  static const String search = '/search';
  static const String addPost = '/add-post';
  static const String postDetails = '/post-details';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminDashboard = '/admin';

  /// Central route generator — plug into [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '/';

    // ── Route Guard ────────────────────────────────────────────────────────
    // We use a builder so we can access Provider without a BuildContext at
    // the top level. The guard fires lazily inside the route widget tree.
    return _guardedRoute(routeName, settings);
  }

  static Route<dynamic> _guardedRoute(
      String routeName, RouteSettings settings) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (context, _, __) {
        // Resolve auth state
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final redirect = RouteGuard.redirect(
          requestedRoute: routeName,
          auth: auth,
        );

        if (redirect != null) {
          return AccessDeniedScreen(redirectTo: redirect);
        }

        return _buildPage(routeName, settings, context);
      },
      transitionsBuilder: _transitionFor(routeName),
      transitionDuration: _durationFor(routeName),
    );
  }

  // ── Page builder ──────────────────────────────────────────────────────────
  static Widget _buildPage(
      String name, RouteSettings settings, BuildContext context) {
    switch (name) {
      case splash:
        return const SplashScreen();

      case onboarding:
        return const OnboardingScreen();

      case login:
        return const LoginScreen();

      case register:
        return const SignUpScreen();

      case bottomNav:
        return const BottomNavScreen();

      case home:
        return const HomeScreen();

      case search:
        return const SearchScreen();

      case addPost:
        return const AddPostScreen();

      case postDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return PostDetailsScreen(postId: args?['postId'] ?? '');

      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return ChatScreen(
          chatId: args?['chatId'] ?? '',
          participantName: args?['participantName'] as String?,
          participantAvatarUrl: args?['participantAvatarUrl'] as String?,
        );

      case profile:
        final args = settings.arguments as Map<String, dynamic>?;
        return ProfileScreen(userId: args?['userId']);

      case editProfile:
        return const EditProfileScreen();

      case adminDashboard:
        return const AdminShellScreen();

      default:
        return _NotFoundScreen(routeName: name);
    }
  }

  // ── Transition helpers ────────────────────────────────────────────────────

  static RouteTransitionsBuilder _transitionFor(String name) {
    if (name == addPost) return _slideUpTransition;
    if (name == splash || name == bottomNav || name == home) {
      return _fadeTransition;
    }
    return _slideTransition;
  }

  static Duration _durationFor(String name) {
    if (name == addPost) return const Duration(milliseconds: 400);
    if (name == splash) return const Duration(milliseconds: 300);
    return const Duration(milliseconds: 350);
  }

  static Widget _fadeTransition(
      BuildContext ctx, Animation<double> a, Animation<double> _, Widget child) {
    return FadeTransition(opacity: a, child: child);
  }

  static Widget _slideTransition(
      BuildContext ctx, Animation<double> a, Animation<double> _, Widget child) {
    final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(position: a.drive(tween), child: child);
  }

  static Widget _slideUpTransition(
      BuildContext ctx, Animation<double> a, Animation<double> _, Widget child) {
    final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(position: a.drive(tween), child: child);
  }
}

/// Fallback screen for unregistered routes.
class _NotFoundScreen extends StatelessWidget {
  final String routeName;
  const _NotFoundScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '404 — Route "$routeName" not found.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
