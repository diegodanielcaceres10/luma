/// Monedas soportadas hoy (lista fija, no editable por el usuario). Código
/// ISO 4217. Si se suma una nueva, agregarla acá y en el mapa de labels de
/// PreferencesScreen.
const List<String> kSupportedCurrencyCodes = ['USD', 'EUR', 'BRL', 'ARS'];

/// Idiomas soportados hoy (lista fija). Código ISO 639-1. Por ahora solo se
/// guarda la preferencia — no cambia el idioma real de la app (ver
/// PreferencesViewModel).
const List<String> kSupportedLanguageCodes = ['es', 'en', 'pt'];

/// Preferencias del usuario que se guardan solo en este dispositivo (ver
/// PreferencesRepository) — no viajan entre dispositivos ni sobreviven a un
/// reinstall. A diferencia del resto de los datos de la app (cuentas,
/// categorías, etc.), no están pensadas para sincronizarse vía Supabase.
///
/// Importante: moneda, idioma, tema y notificaciones por ahora solo se
/// guardan — todavía no cambian nada del comportamiento real de la app.
/// [biometricLockEnabled] es la excepción: sí se aplica de verdad, ver
/// AppLockViewModel (feature `app_lock`).
class AppPreferences {
  final String currencyCode;
  final String languageCode;
  final bool darkThemeEnabled;
  final bool notificationsEnabled;

  /// Con cuántos días de anticipación avisar antes del vencimiento de una
  /// factura. Solo tiene sentido si [notificationsEnabled] es `true`.
  final int invoiceReminderDaysAhead;

  /// Preferencia de bloqueo con biometría. Se aplica de verdad: cuando
  /// está en `true` (y el dispositivo lo soporta), `AppLockViewModel`
  /// bloquea la app al abrirla y al volver de segundo plano, pidiendo
  /// Face ID/huella/PIN vía `local_auth` — ver feature `app_lock`.
  final bool biometricLockEnabled;

  const AppPreferences({
    required this.currencyCode,
    required this.languageCode,
    required this.darkThemeEnabled,
    required this.notificationsEnabled,
    required this.invoiceReminderDaysAhead,
    required this.biometricLockEnabled,
  });

  static const defaultCurrencyCode = 'USD';
  static const defaultLanguageCode = 'es';
  static const defaultInvoiceReminderDaysAhead = 3;

  const AppPreferences.defaults()
      : currencyCode = defaultCurrencyCode,
        languageCode = defaultLanguageCode,
        darkThemeEnabled = false,
        notificationsEnabled = true,
        invoiceReminderDaysAhead = defaultInvoiceReminderDaysAhead,
        biometricLockEnabled = false;

  AppPreferences copyWith({
    String? currencyCode,
    String? languageCode,
    bool? darkThemeEnabled,
    bool? notificationsEnabled,
    int? invoiceReminderDaysAhead,
    bool? biometricLockEnabled,
  }) {
    return AppPreferences(
      currencyCode: currencyCode ?? this.currencyCode,
      languageCode: languageCode ?? this.languageCode,
      darkThemeEnabled: darkThemeEnabled ?? this.darkThemeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      invoiceReminderDaysAhead:
          invoiceReminderDaysAhead ?? this.invoiceReminderDaysAhead,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
    );
  }
}
