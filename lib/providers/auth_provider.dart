import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Supabase client singleton ───────────────────────────────────
final supabaseProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// ── Auth state stream ───────────────────────────────────────────
// Emits the current Session (or null if signed out)
final authStateProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.onAuthStateChange.map((event) => event.session);
});

// ── Current user (convenience) ─────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// ── Auth service ────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseProvider));
});

class AuthService {
  AuthService(this._client);
  final SupabaseClient _client;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'username': username},
      );

  Future<void> signOut() => _client.auth.signOut();

  Future<void> signInWithGoogle() =>
      _client.auth.signInWithOAuth(OAuthProvider.google);

  User? get currentUser => _client.auth.currentUser;
  bool  get isSignedIn  => currentUser != null;
}