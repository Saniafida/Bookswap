import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Encapsulates all Supabase authentication operations.
/// The AuthProvider delegates every auth call to this service,
/// keeping raw SDK references out of the presentation layer.
class SupabaseAuthService {
  const SupabaseAuthService._();

  // ── Sign Up ───────────────────────────────────────────────────────────────
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) =>
      SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

  // ── Sign In (email / password) ────────────────────────────────────────────
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );

  // ── Google OAuth ──────────────────────────────────────────────────────────
  /// Opens the Google consent screen via Supabase OAuth (PKCE flow).
  /// On mobile the redirect is handled by the deep-link setup in the app;
  /// on web it opens in the same tab.
  static Future<bool> signInWithGoogle() =>
      SupabaseService.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.bookswap://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

  // ── Sign Out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() => SupabaseService.auth.signOut();

  // ── Current User ─────────────────────────────────────────────────────────
  static User? get currentUser => SupabaseService.currentUser;

  // ── Auth State Stream ─────────────────────────────────────────────────────
  static Stream<AuthState> get authStateStream =>
      SupabaseService.authStateStream;
}
