/// Build-time config injected via `--dart-define-from-file=.env` (see README).
///
/// Values are compiled into the binary instead of shipped as an asset, which
/// Flutter web would serve publicly. `String.fromEnvironment` only works with
/// const literal keys, hence one declaration per variable; missing values
/// are empty strings.
class AppEnv {
  AppEnv._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  // Firebase web app, only needed for push on the PWA. The same values are
  // injected into the service worker at build time.
  static const firebaseWebApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const firebaseWebAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const firebaseVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

  /// Whether the web build has everything push needs. Without it the web app
  /// behaves as if notifications were not available.
  static const webPushConfigured = firebaseWebApiKey != '' &&
      firebaseWebAppId != '' &&
      firebaseMessagingSenderId != '' &&
      firebaseProjectId != '' &&
      firebaseVapidKey != '';
}
