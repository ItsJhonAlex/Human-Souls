import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../mock/mock_session.dart';

class AuthService {
  final SupabaseClient? _client;
  AuthService(this._client);

  Session? get session => _client?.auth.currentSession;
  User? get currentUser => _client?.auth.currentUser;
  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  /// Login con email + contraseña.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMock) {
      MockSession.instance.signIn();
      return;
    }
    await _client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registro con email.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    if (AppConfig.useMock) {
      MockSession.instance.signIn();
      return;
    }
    await _client!.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
      },
    );
  }

  /// OAuth con Google.
  Future<void> signInWithGoogle() async {
    if (AppConfig.useMock) {
      MockSession.instance.signIn();
      return;
    }
    await _client!.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signOut() async {
    if (AppConfig.useMock) {
      MockSession.instance.signOut();
      return;
    }
    await _client!.auth.signOut();
  }

  /// Reset de contraseña por email.
  Future<void> sendPasswordReset(String email) async {
    if (AppConfig.useMock) return;
    await _client!.auth.resetPasswordForEmail(email.trim());
  }
}
