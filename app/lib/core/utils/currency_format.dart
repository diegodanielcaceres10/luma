import 'package:intl/intl.dart';

/// How amounts show their currency. Chosen in Preferences and stored by
/// [name], so do not rename a value without migrating the stored one.
enum CurrencyDisplay {
  /// ISO code after the amount: '2.480,75 USD'.
  code,

  /// Symbol after the amount: '2.480,75 US$'.
  symbol;

  static const defaultDisplay = CurrencyDisplay.code;

  /// Restores a stored [name]; a missing or unknown one gives
  /// [defaultDisplay].
  static CurrencyDisplay parse(String? name) =>
      values.asNameMap()[name] ?? defaultDisplay;
}

// 'US$' keeps the dollar apart from the Argentine peso, which uses '$'.
const _currencySymbols = {
  'USD': 'US\$',
  'EUR': '€',
  'BRL': 'R\$',
  'ARS': '\$',
};

/// Symbol shown by [CurrencyDisplay.symbol] for [currencyCode]; falls back to
/// the code itself when there is no known symbol.
String currencySymbolFor(String currencyCode) =>
    _currencySymbols[currencyCode] ?? currencyCode;

/// Formats an amount using Spanish conventions: '2.480,75 EUR', or
/// '2.480,75 €' with [CurrencyDisplay.symbol].
String formatCurrency(
  double amount,
  String currencyCode, {
  CurrencyDisplay display = CurrencyDisplay.defaultDisplay,
}) {
  final format = NumberFormat.currency(
    locale: 'es_ES',
    name: currencyCode,
    symbol: display == CurrencyDisplay.symbol
        ? currencySymbolFor(currencyCode)
        : null,
  );
  return format.format(amount);
}

/// Symbol [formatCurrency] uses for [currencyCode] (e.g. '€' for 'EUR').
String currencySymbol(String currencyCode) {
  return NumberFormat.currency(locale: 'es_ES', name: currencyCode)
      .currencySymbol;
}
