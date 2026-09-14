import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Deep link al que Supabase devuelve la sesión tras el login con Google.
  /// Debe coincidir con:
  ///  - el intent-filter de android/app/src/main/AndroidManifest.xml
  ///  - el CFBundleURLSchemes de ios/Runner/Info.plist
  ///  - las Redirect URLs del proyecto en Supabase
  static const oauthRedirectUrl = 'io.luma.app://login-callback';

  Future<bool> signInWithGoogle() async {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      // En web el redirect lo maneja el propio navegador; en móvil hace falta
      // el deep link para que la sesión vuelva a la app.
      redirectTo: kIsWeb ? null : oauthRedirectUrl,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
