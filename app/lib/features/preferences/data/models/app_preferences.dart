/// Monedas soportadas hoy (lista fija, no editable por el usuario). Código
/// ISO 4217. Si se suma una nueva, agregarla acá y en el mapa de labels de
/// PreferencesScreen.
const List<String> kSupportedCurrencyCodes = ['USD', 'EUR', 'BRL', 'ARS'];

/// Preferencias del usuario que se guardan solo en este dispositivo (ver
/// PreferencesRepository) — no viajan entre dispositivos ni sobreviven a un
/// reinstall. A diferencia del resto de los datos de la app (cuentas,
/// categorías, etc.), no están pensadas para sincronizarse vía Supabase.
///
/// Importante: moneda y tema por ahora solo se guardan — todavía no
/// cambian nada del comportamiento real de la app. [biometricLockEnabled]
/// y [notificationsEnabled] son la excepción: sí se aplican de verdad —
/// ver AppLockViewModel (feature `app_lock`) y NotificationsViewModel /
/// NotificationSchedulerService (feature `notifications`),
/// respectivamente.
class AppPreferences {
  final String currencyCode;
  final bool darkThemeEnabled;
  final bool notificationsEnabled;

  /// Preferencia de bloqueo con biometría. Se aplica de verdad: cuando
  /// está en `true` (y el dispositivo lo soporta), `AppLockViewModel`
  /// bloquea la app al abrirla y al volver de segundo plano, pidiendo
  /// Face ID/huella/PIN vía `local_auth` — ver feature `app_lock`.
  final bool biometricLockEnabled;

  const AppPreferences({
    required this.currencyCode,
    required this.darkThemeEnabled,
    required this.notificationsEnabled,
    required this.biometricLockEnabled,
  });

  static const defaultCurrencyCode = 'USD';

  const AppPreferences.defaults()
      : currencyCode = defaultCurrencyCode,
        darkThemeEnabled = false,
        notificationsEnabled = false,
        biometricLockEnabled = false;

  AppPreferences copyWith({
    String? currencyCode,
    bool? darkThemeEnabled,
    bool? notificationsEnabled,
    bool? biometricLockEnabled,
  }) {
    return AppPreferences(
      currencyCode: currencyCode ?? this.currencyCode,
      darkThemeEnabled: darkThemeEnabled ?? this.darkThemeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
    );
  }
}
