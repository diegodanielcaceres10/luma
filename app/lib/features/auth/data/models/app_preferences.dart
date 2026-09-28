/// Supported ISO 4217 currency codes. A new code also needs a label in
/// PreferencesScreen.
const List<String> kSupportedCurrencyCodes = ['USD', 'EUR', 'BRL', 'ARS'];

/// User preferences stored only on this device (see PreferencesRepository).
///
/// Currency and theme are only stored for now; [biometricLockEnabled] and
/// [notificationsEnabled] are applied by AppLockViewModel and
/// NotificationsViewModel.
class AppPreferences {
  final String currencyCode;
  final bool darkThemeEnabled;
  final bool notificationsEnabled;

  /// When true (and supported), AppLockViewModel locks the app on open and
  /// on resume.
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
