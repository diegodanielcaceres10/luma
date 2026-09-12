import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  Future<bool> signInWithGoogle() async {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Session? get currentSession {
    return _client.auth.currentSession;
  }

  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }
}
