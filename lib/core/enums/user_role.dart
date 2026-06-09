/// Defines every role a BookSwap user can have.
///
/// Add new roles here as the product grows; the rest of the app
/// (PermissionHelper, RouteGuard, UI badges) adapts automatically.
enum UserRole {
  admin,
  user;

  // ── Factories ─────────────────────────────────────────────────────────────

  /// Parses a raw DB string. Defaults to [UserRole.user] for unknown values
  /// so a malformed DB row never crashes the app.
  factory UserRole.fromString(String? raw) {
    if (raw == null) return UserRole.user;
    return UserRole.values.firstWhere(
      (r) => r.name == raw.toLowerCase().trim(),
      orElse: () => UserRole.user,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Human-readable label for UI display.
  String get displayName => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.user => 'User',
      };

  /// Short badge label shown in admin lists.
  String get badgeLabel => switch (this) {
        UserRole.admin => 'ADMIN',
        UserRole.user => 'USER',
      };

  bool get isAdmin => this == UserRole.admin;
  bool get isUser => this == UserRole.user;
}
