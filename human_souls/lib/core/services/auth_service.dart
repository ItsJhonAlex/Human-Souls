import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  Session? get session => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Login con email + contraseña.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registro con email. Supabase envía mail de verificación automáticamente
  /// si está configurado en el dashboard.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
      },
    );
  }

  /// OAuth con Google. En web abre popup, en mobile abre browser externo.
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      // redirectTo puede configurarse en Env si se usa deep link personalizado.
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Reset de contraseña por email.
  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }
}
