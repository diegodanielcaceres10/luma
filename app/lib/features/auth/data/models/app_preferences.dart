/// Supported ISO 4217 currency codes. A new code also needs a label in
/// PreferencesScreen.
const List<String> kSupportedCurrencyCodes = ['USD', 'EUR', 'BRL', 'ARS'];

/// User preferences stored only on this device (see PreferencesRepository).
///
/// [biometricLockEnabled] and [notificationsEnabled] are applied by
/// AppLockViewModel and NotificationsViewModel.
class AppPreferences {
  final String currencyCode;
  final bool notificationsEnabled;

  /// Allows balance reconciliation flows to keep an uncovered difference.
  final bool uncontrolledExpensesEnabled;

  /// When true (and supported), AppLockViewModel locks the app on open and
  /// on resume.
  final bool biometricLockEnabled;

  const AppPreferences({
    required this.currencyCode,
    required this.notificationsEnabled,
    required this.uncontrolledExpensesEnabled,
    required this.biometricLockEnabled,
  });

  static const defaultCurrencyCode = 'USD';

  const AppPreferences.defaults()
      : currencyCode = defaultCurrencyCode,
        notificationsEnabled = false,
        uncontrolledExpensesEnabled = false,
        biometricLockEnabled = false;

  AppPreferences copyWith({
    String? currencyCode,
    bool? notificationsEnabled,
    bool? uncontrolledExpensesEnabled,
    bool? biometricLockEnabled,
  }) {
    return AppPreferences(
      currencyCode: currencyCode ?? this.currencyCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      uncontrolledExpensesEnabled:
          uncontrolledExpensesEnabled ?? this.uncontrolledExpensesEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
    );
  }
}
