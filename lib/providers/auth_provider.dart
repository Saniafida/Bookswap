import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_auth_service.dart';
import '../core/services/supabase_service.dart';
import '../core/services/role_service.dart';
import '../core/enums/user_role.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isFetching = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// The current user's role — null when not authenticated.
  UserRole? get currentRole => _currentUser?.role;

  /// True when the authenticated user has admin privileges.
  bool get isAdmin => currentRole?.isAdmin ?? false;

  // ── Constructor ───────────────────────────────────────────────────────────
  AuthProvider() {
    _listenToAuthChanges();
  }

  // ── Auth State Listener ───────────────────────────────────────────────────
  void _listenToAuthChanges() {
    SupabaseAuthService.authStateStream.listen((AuthState state) {
      if (state.event == AuthChangeEvent.signedIn) {
        if (_status != AuthStatus.authenticated && _status != AuthStatus.loading) {
          _fetchCurrentUser();
        }
      } else if (state.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });

    // Check if already signed in on startup
    final user = SupabaseAuthService.currentUser;
    if (user != null) {
      _fetchCurrentUser();
    } else {
      _status = AuthStatus.unauthenticated;
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setLoading();
    try {
      final response = await SupabaseAuthService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (response.user != null) {
        // Ensure profile + role are written to DB (trigger fallback).
        final role = RoleService.resolveRole(response.user!.id);
        await RoleService.setRoleInDb(response.user!.id, role, email: email, fullName: fullName);

        // If session is null, email confirmation is required
        if (response.session == null) {
          _status = AuthStatus.unauthenticated;
          _errorMessage = 'Please check your email to confirm your account.';
          notifyListeners();
          return true;
        }

        await _fetchCurrentUser();
        return true;
      }
      _setError('Sign up failed. Please try again.');
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  // ── Sign In (email / password) ────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final response = await SupabaseAuthService.signIn(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _fetchCurrentUser();
        return true;
      }
      _setError('Invalid credentials. Please try again.');
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  /// Launches the Google OAuth consent screen.
  /// The auth state listener automatically handles the callback and updates
  /// [status] to [AuthStatus.authenticated] on success.
  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      final launched = await SupabaseAuthService.signInWithGoogle();
      if (!launched) {
        _setError('Could not open Google sign-in. Please try again.');
        return false;
      }
      // Status will be updated by _listenToAuthChanges on OAuth callback.
      // Reset loading so the UI is not stuck while the browser is open.
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed') || msg.contains('invalid login credentials')) {
        _setError('Please confirm your email first. Check your inbox (and spam folder).');
      } else {
        _setError(e.message);
      }
      return false;
    } catch (_) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading();
    try {
      await SupabaseAuthService.signOut();
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      notifyListeners();
    }
  }

  // ── Fetch User Profile ────────────────────────────────────────────────────
  Future<void> _fetchCurrentUser() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final supabaseUser = SupabaseAuthService.currentUser;
      if (supabaseUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      final data = await SupabaseService.table('profiles')
          .select()
          .eq('id', supabaseUser.id)
          .single();

      // Fetch authoritative role from DB; fall back to UID comparison.
      final dbRole = await RoleService.fetchRoleFromDb(supabaseUser.id);

      _currentUser = UserModel.fromJson(data).copyWith(role: dbRole);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Profile fetch failed (e.g. no row in profiles table yet).
      // Fall back to Supabase Auth user data so the user stays logged in.
      final supabaseUser = SupabaseAuthService.currentUser;
      if (supabaseUser != null) {
        _currentUser = UserModel(
          id: supabaseUser.id,
          email: supabaseUser.email ?? '',
          fullName: supabaseUser.userMetadata?['full_name'] as String? ?? '',
          createdAt: supabaseUser.createdAt is DateTime
              ? supabaseUser.createdAt as DateTime
              : DateTime.now(),
          role: RoleService.resolveRole(supabaseUser.id),
        );
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
        // Attempt to create the missing profile row
        try {
          await RoleService.setRoleInDb(
            supabaseUser.id,
            _currentUser!.role,
            email: supabaseUser.email ?? '',
            fullName: supabaseUser.userMetadata?['full_name'] as String? ?? '',
          );
        } catch (_) {}
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } finally {
      _isFetching = false;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Keeps auth state in sync after profile edits.
  void updateCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    await _fetchCurrentUser();
  }
}
