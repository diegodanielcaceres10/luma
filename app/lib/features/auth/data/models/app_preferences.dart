import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';

/// Supported ISO 4217 currency codes. A new code also needs a label in
/// PreferencesScreen.
const List<String> kSupportedCurrencyCodes = ['USD', 'EUR', 'BRL', 'ARS'];

/// User preferences stored only on this device (see PreferencesRepository).
///
/// Currency, theme, [dateFormat] and [currencyDisplay] are only stored for
/// now; [biometricLockEnabled] and [notificationsEnabled] are applied by
/// AppLockViewModel and NotificationsViewModel.
class AppPreferences {
  final String currencyCode;
  final bool darkThemeEnabled;
  final bool notificationsEnabled;

  /// How dates are shown; see [formatDate].
  final DateDisplayFormat dateFormat;

  /// Whether amounts show the currency code or its symbol; see
  /// [formatCurrency].
  final CurrencyDisplay currencyDisplay;

  /// When true (and supported), AppLockViewModel locks the app on open and
  /// on resume.
  final bool biometricLockEnabled;

  const AppPreferences({
    required this.currencyCode,
    required this.darkThemeEnabled,
    required this.notificationsEnabled,
    required this.biometricLockEnabled,
    required this.dateFormat,
    required this.currencyDisplay,
  });

  static const defaultCurrencyCode = 'USD';

  const AppPreferences.defaults()
      : currencyCode = defaultCurrencyCode,
        darkThemeEnabled = false,
        notificationsEnabled = false,
        biometricLockEnabled = false,
        dateFormat = DateDisplayFormat.defaultFormat,
        currencyDisplay = CurrencyDisplay.defaultDisplay;

  AppPreferences copyWith({
    String? currencyCode,
    bool? darkThemeEnabled,
    bool? notificationsEnabled,
    bool? biometricLockEnabled,
    DateDisplayFormat? dateFormat,
    CurrencyDisplay? currencyDisplay,
  }) {
    return AppPreferences(
      currencyCode: currencyCode ?? this.currencyCode,
      darkThemeEnabled: darkThemeEnabled ?? this.darkThemeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      dateFormat: dateFormat ?? this.dateFormat,
      currencyDisplay: currencyDisplay ?? this.currencyDisplay,
    );
  }
}
