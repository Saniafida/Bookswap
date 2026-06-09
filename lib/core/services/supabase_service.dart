import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase initialization and exposes typed client accessors.
/// Call [SupabaseService.initialize] once in main() before runApp().
class SupabaseService {
  SupabaseService._();

  // ─── Replace these with your actual Supabase project credentials ──────────
  static const String _supabaseUrl = 'https://spaajdvtlpvdofajrkwx.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwYWFqZHZ0bHB2ZG9mYWpya3d4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MDYzMDIsImV4cCI6MjA5NjQ4MjMwMn0.HIVJ1zDbRQ9GbBY5H9N7fEY5RhSUrF7wy2Klen5qJUU';
  // ─────────────────────────────────────────────────────────────────────────

  /// Initializes the Supabase SDK. Call once before [runApp].
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  /// Direct access to the Supabase client.
  static SupabaseClient get client => Supabase.instance.client;

  /// Direct access to the Supabase auth client.
  static GoTrueClient get auth => Supabase.instance.client.auth;

  /// Currently logged-in user; null when unauthenticated.
  static User? get currentUser => Supabase.instance.client.auth.currentUser;

  /// Typed shorthand for a table query.
  static SupabaseQueryBuilder table(String tableName) =>
      Supabase.instance.client.from(tableName);

  /// Typed shorthand for Supabase storage.
  static SupabaseStorageClient get storage =>
      Supabase.instance.client.storage;

  /// Auth state change stream.
  static Stream<AuthState> get authStateStream =>
      Supabase.instance.client.auth.onAuthStateChange;
}
