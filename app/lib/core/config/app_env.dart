/// Configuración de la app que se inyecta al compilar con
/// `--dart-define-from-file=.env` (ver README).
///
/// Los valores quedan compilados dentro del binario en vez de viajar como un
/// archivo `.env` aparte: en Flutter web un asset se sirve tal cual desde
/// `/assets/.env`, y cualquiera que abra el sitio podría descargarlo.
///
/// `String.fromEnvironment` solo funciona con claves literales y `const`, por
/// eso cada variable se declara explícitamente acá. Si falta alguna, el valor
/// es una cadena vacía.
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
