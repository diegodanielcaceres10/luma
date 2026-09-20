import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleSignInInitialization;

  AuthService(this._client);

  /// Deep link al que Supabase devuelve la sesión tras el login con Google.
  /// Debe coincidir con:
  ///  - el intent-filter de android/app/src/main/AndroidManifest.xml
  ///  - el CFBundleURLSchemes de ios/Runner/Info.plist
  ///  - las Redirect URLs del proyecto en Supabase
  static const oauthRedirectUrl = 'io.luma.app://login-callback';

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw const AuthException(
        'Google native sign-in is only configured for Android and iOS.',
      );
    }

    await _initializeGoogleSignIn();

    final googleAccount = await _googleSignIn.authenticate();
    final googleAuthentication = googleAccount.authentication;
    final googleAuthorization =
        await googleAccount.authorizationClient.authorizationForScopes(
              const <String>[],
            ) ??
            await googleAccount.authorizationClient.authorizeScopes(
              const <String>[],
            );

    final idToken = googleAuthentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google did not return an ID token.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuthorization.accessToken,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    if (_googleSignInInitialization != null) {
      await _googleSignIn.signOut();
    }
  }

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> _initializeGoogleSignIn() {
    return _googleSignInInitialization ??= _googleSignIn.initialize(
      clientId: _nativeClientId,
      serverClientId: _requiredEnv('GOOGLE_WEB_CLIENT_ID'),
    );
  }

  String? get _nativeClientId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _requiredEnv('GOOGLE_IOS_CLIENT_ID');
      case TargetPlatform.android:
        return null;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return null;
    }
  }

  String _requiredEnv(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw AuthException('Missing $key in .env.');
    }
    return value;
  }
}
