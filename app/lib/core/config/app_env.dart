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
}
