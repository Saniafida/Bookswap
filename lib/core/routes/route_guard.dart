import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import '../utils/permission_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RouteGuard — bidirectional role-based route protection
//
//  Rules:
//   1. Unauthenticated user → /login
//   2. Admin accessing a user-only route → /admin  (admin CAN'T use user app)
//   3. User accessing an admin-only route → /home   (user CAN'T use admin app)
// ─────────────────────────────────────────────────────────────────────────────

class RouteGuard {
  const RouteGuard._();

  // ── Route buckets ─────────────────────────────────────────────────────────

  /// Routes that require any authenticated session.
  static const Set<String> _protectedRoutes = {
    '/home',
    '/home/feed',
    '/search',
    '/add-post',
    '/post-details',
    '/chat',
    '/profile',
    '/edit-profile',
    '/admin',
  };

  /// Routes exclusively for admin users.
  static const Set<String> _adminOnlyRoutes = {
    '/admin',
  };

  /// Routes exclusively for regular users (admin should not land here).
  static const Set<String> _userOnlyRoutes = {
    '/home',
    '/home/feed',
    '/search',
    '/add-post',
    '/profile',
    '/edit-profile',
    '/chat',
  };

  // ── Guard logic ───────────────────────────────────────────────────────────

  /// Returns the route to redirect to, or `null` if access is granted.
  static String? redirect({
    required String requestedRoute,
    required AuthProvider auth,
  }) {
    final isProtected = _protectedRoutes.contains(requestedRoute);

    // ── 1. Not authenticated ──────────────────────────────────────────────
    if (isProtected && !auth.isAuthenticated) {
      return '/login';
    }

    if (!auth.isAuthenticated) return null;

    // ── 2. Admin trying to access user-only routes → send to admin panel ──
    if (auth.isAdmin && _userOnlyRoutes.contains(requestedRoute)) {
      return '/admin';
    }

    // ── 3. Regular user trying to access admin-only routes → send to home ─
    if (!auth.isAdmin &&
        !PermissionHelper.canAccessAdmin(auth.currentRole) &&
        _adminOnlyRoutes.contains(requestedRoute)) {
      return '/home';
    }

    return null; // Access granted
  }

  /// Whether [route] requires admin privileges.
  static bool isAdminRoute(String route) => _adminOnlyRoutes.contains(route);

  /// Whether [route] is user-only (no admin access).
  static bool isUserRoute(String route) => _userOnlyRoutes.contains(route);
}

// ─────────────────────────────────────────────────────────────────────────────
//  AccessDeniedScreen — lightweight redirect shown during guard transitions
// ─────────────────────────────────────────────────────────────────────────────

class AccessDeniedScreen extends StatelessWidget {
  final String redirectTo;
  const AccessDeniedScreen({super.key, required this.redirectTo});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(redirectTo);
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
