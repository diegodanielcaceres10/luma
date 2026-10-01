import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
import '../models/app_preferences.dart';

/// Persists [AppPreferences] on this device with `SharedPreferencesAsync`.
/// There is no separate service layer because there is no network client.
class PreferencesRepository {
  final SharedPreferencesAsync _prefs;

  PreferencesRepository({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const _currencyCodeKey = 'preferences.currency_code';
  static const _darkThemeEnabledKey = 'preferences.dark_theme_enabled';
  static const _notificationsEnabledKey = 'preferences.notifications_enabled';
  static const _biometricLockEnabledKey = 'preferences.biometric_lock_enabled';
  static const _dateFormatKey = 'preferences.date_format';
  static const _currencyDisplayKey = 'preferences.currency_display';

  /// Loads the saved preferences; missing values fall back to
  /// [AppPreferences.defaults].
  Future<AppPreferences> load() async {
    const defaults = AppPreferences.defaults();

    final currencyCode = await _prefs.getString(_currencyCodeKey);
    final darkThemeEnabled = await _prefs.getBool(_darkThemeEnabledKey);
    final notificationsEnabled = await _prefs.getBool(_notificationsEnabledKey);
    final biometricLockEnabled = await _prefs.getBool(_biometricLockEnabledKey);
    final dateFormat = await _prefs.getString(_dateFormatKey);
    final currencyDisplay = await _prefs.getString(_currencyDisplayKey);

    return AppPreferences(
      currencyCode: currencyCode ?? defaults.currencyCode,
      darkThemeEnabled: darkThemeEnabled ?? defaults.darkThemeEnabled,
      notificationsEnabled:
          notificationsEnabled ?? defaults.notificationsEnabled,
      biometricLockEnabled:
          biometricLockEnabled ?? defaults.biometricLockEnabled,
      dateFormat: DateDisplayFormat.parse(dateFormat),
      currencyDisplay: CurrencyDisplay.parse(currencyDisplay),
    );
  }

  Future<void> setCurrencyCode(String value) =>
      _prefs.setString(_currencyCodeKey, value);

  Future<void> setDarkThemeEnabled(bool value) =>
      _prefs.setBool(_darkThemeEnabledKey, value);

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_notificationsEnabledKey, value);

  Future<void> setBiometricLockEnabled(bool value) =>
      _prefs.setBool(_biometricLockEnabledKey, value);

  Future<void> setDateFormat(DateDisplayFormat value) =>
      _prefs.setString(_dateFormatKey, value.name);

  Future<void> setCurrencyDisplay(CurrencyDisplay value) =>
      _prefs.setString(_currencyDisplayKey, value.name);
}
