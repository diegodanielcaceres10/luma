import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_preferences.dart';

/// Persists [AppPreferences] on this device with `SharedPreferencesAsync`.
/// There is no separate service layer because there is no network client.
class PreferencesRepository {
  final SharedPreferencesAsync _prefs;

  PreferencesRepository({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const _currencyCodeKey = 'preferences.currency_code';
  static const _notificationsEnabledKey = 'preferences.notifications_enabled';
  static const _uncontrolledExpensesEnabledKey =
      'preferences.uncontrolled_expenses_enabled';
  static const _biometricLockEnabledKey = 'preferences.biometric_lock_enabled';

  /// Loads the saved preferences; missing values fall back to
  /// [AppPreferences.defaults].
  Future<AppPreferences> load() async {
    const defaults = AppPreferences.defaults();

    final currencyCode = await _prefs.getString(_currencyCodeKey);
    final notificationsEnabled = await _prefs.getBool(_notificationsEnabledKey);
    final uncontrolledExpensesEnabled =
        await _prefs.getBool(_uncontrolledExpensesEnabledKey);
    final biometricLockEnabled = await _prefs.getBool(_biometricLockEnabledKey);

    return AppPreferences(
      currencyCode: currencyCode ?? defaults.currencyCode,
      notificationsEnabled:
          notificationsEnabled ?? defaults.notificationsEnabled,
      uncontrolledExpensesEnabled:
          uncontrolledExpensesEnabled ?? defaults.uncontrolledExpensesEnabled,
      biometricLockEnabled:
          biometricLockEnabled ?? defaults.biometricLockEnabled,
    );
  }

  Future<void> setCurrencyCode(String value) =>
      _prefs.setString(_currencyCodeKey, value);

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_notificationsEnabledKey, value);

  Future<void> setUncontrolledExpensesEnabled(bool value) =>
      _prefs.setBool(_uncontrolledExpensesEnabledKey, value);

  Future<void> setBiometricLockEnabled(bool value) =>
      _prefs.setBool(_biometricLockEnabledKey, value);
}
