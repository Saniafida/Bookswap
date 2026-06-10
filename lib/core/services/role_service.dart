import '../enums/user_role.dart';
import '../services/supabase_service.dart';

/// The single admin UID — change this to rotate the admin account
/// without any database migration.
const String kAdminUid = '23e1e885-ce66-4740-9c75-404b1a1f6b23';

/// Handles all role resolution and persistence logic.
///
/// Two paths:
///  1. [resolveRole] — fast, in-memory check against [kAdminUid].
///     Used when you already know the UID and don't need a DB round-trip.
///  2. [fetchRoleFromDb] — reads the `profiles.role` column (source of
///     truth after the Supabase trigger has run).
///
/// To add a new role tier, update [UserRole], adjust [resolveRole], and
/// add a corresponding row to the Supabase `user_roles` enum type.
class RoleService {
  const RoleService._();

  // ── In-memory role resolution (instant) ───────────────────────────────────

  /// Compares [uid] to [kAdminUid] and returns the matching [UserRole].
  /// Falls back to [UserRole.user] for every other UID.
  static UserRole resolveRole(String uid) {
    return uid == kAdminUid ? UserRole.admin : UserRole.user;
  }

  // ── Database role fetch ────────────────────────────────────────────────────

  /// Reads the `role` column from the `profiles` table.
  /// The Supabase trigger is the authoritative source; this method
  /// is called during [AuthProvider._fetchCurrentUser] to stay in sync.
  static Future<UserRole> fetchRoleFromDb(String uid) async {
    try {
      final data = await SupabaseService.table('profiles')
          .select('role')
          .eq('id', uid)
          .single();
      return UserRole.fromString(data['role'] as String?);
    } catch (_) {
      // Fallback: derive from UID so the app still works if the column
      // doesn't exist yet (before the migration runs).
      return resolveRole(uid);
    }
  }

  // ── Database role upsert ──────────────────────────────────────────────────

  /// Inserts or updates [role] in `profiles`.
  /// Creates the profile row if it doesn't exist (trigger fallback).
  static Future<void> setRoleInDb(String uid, UserRole role, {String email = '', String fullName = ''}) async {
    try {
      await SupabaseService.table('profiles')
          .upsert({
            'id': uid,
            'email': email,
            'full_name': fullName,
            'role': role.name,
          });
    } catch (_) {
      // Non-fatal: best-effort profile creation.
    }
  }

  // ── Convenience check ─────────────────────────────────────────────────────

  /// Quick check without a DB round-trip — suitable for UI gating.
  static bool isAdmin(String? uid) => uid == kAdminUid;
}
