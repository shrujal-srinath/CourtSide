import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';

// ── Dev access bypass ───────────────────────────────────────────
final devAccessProvider = StateProvider<bool>((ref) => false);

// ── Supabase client singleton ───────────────────────────────────
final supabaseProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// ── Auth state stream ───────────────────────────────────────────
// Emits the current Session (or null if signed out)
// Includes error handling for network timeouts and auth failures
final authStateProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseProvider);
  // onAuthStateChange is a persistent broadcast stream — do NOT add
  // .timeout() or .handleError() as these close the stream and prevent
  // sign-in/sign-out events from reaching the router.
  return client.auth.onAuthStateChange.map((event) => event.session);
});

// ── Current user (convenience) ─────────────────────────────────
// value is AsyncData<Session?> — use .when() or .asData?.value
final currentUserProvider = Provider<User?>((ref) {
  final asyncSession = ref.watch(authStateProvider);
  return asyncSession.asData?.value?.user;
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
      _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConstants.redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

  User?  get currentUser => _client.auth.currentUser;
  bool   get isSignedIn  => currentUser != null;
}