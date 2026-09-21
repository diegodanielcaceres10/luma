import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_env.dart';

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

  /// Scopes mínimos para obtener un accessToken de Google válido.
  /// En Android, `AuthorizationRequest.Builder.setRequestedScopes` rechaza
  /// una lista vacía con `IllegalArgumentException: requestedScopes cannot
  /// be null or empty`, por eso no se puede pedir `const <String>[]`.
  static const _authorizationScopes = <String>['email'];

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
              _authorizationScopes,
            ) ??
            await googleAccount.authorizationClient.authorizeScopes(
              _authorizationScopes,
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
      serverClientId: _requiredEnv(
        AppEnv.googleWebClientId,
        'GOOGLE_WEB_CLIENT_ID',
      ),
    );
  }

  String? get _nativeClientId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _requiredEnv(AppEnv.googleIosClientId, 'GOOGLE_IOS_CLIENT_ID');
      case TargetPlatform.android:
        return null;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return null;
    }
  }

  String _requiredEnv(String rawValue, String key) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      throw AuthException(
        'Missing $key. Run the app with --dart-define-from-file=.env.',
      );
    }
    return value;
  }
}
