import '../enums/user_role.dart';

/// Centralised permission helper.
///
/// Every access decision in the app should go through one of these
/// static methods instead of comparing roles directly, so permissions
/// can be updated in a single place as requirements evolve.
class PermissionHelper {
  const PermissionHelper._();

  // ── Admin gate ────────────────────────────────────────────────────────────

  /// True when the user can access admin-only areas (dashboard, reports).
  static bool canAccessAdmin(UserRole? role) => role?.isAdmin ?? false;

  // ── Content management ────────────────────────────────────────────────────

  /// Any authenticated user can create/edit their own posts.
  static bool canManagePosts(UserRole? role) => role != null;

  /// Only admins can delete or moderate any post.
  static bool canDeleteAnyPost(UserRole? role) => role?.isAdmin ?? false;

  /// Only admins can flag / resolve reported content.
  static bool canResolveReports(UserRole? role) => role?.isAdmin ?? false;

  // ── User management ───────────────────────────────────────────────────────

  /// Only admins can view the full user list or change another user's role.
  static bool canManageUsers(UserRole? role) => role?.isAdmin ?? false;

  // ── Analytics ─────────────────────────────────────────────────────────────

  /// Only admins see platform-wide stats.
  static bool canViewAnalytics(UserRole? role) => role?.isAdmin ?? false;

  // ── Generic guard ─────────────────────────────────────────────────────────

  /// Pass a minimum required role and the current role to check access.
  /// Useful for route guard tables.
  static bool hasMinimumRole({
    required UserRole required,
    required UserRole? current,
  }) {
    if (current == null) return false;
    // Role hierarchy: admin > user
    const hierarchy = [UserRole.user, UserRole.admin];
    return hierarchy.indexOf(current) >= hierarchy.indexOf(required);
  }
}
