import 'package:intl/intl.dart';

/// Formats an amount using Spanish conventions: '2.480,75 €'.
String formatCurrency(double amount, String currencyCode) {
  final format = NumberFormat.currency(locale: 'es_ES', name: currencyCode);
  return format.format(amount);
}

/// Symbol [formatCurrency] uses for [currencyCode] (e.g. '€' for 'EUR').
String currencySymbol(String currencyCode) {
  return NumberFormat.currency(locale: 'es_ES', name: currencyCode)
      .currencySymbol;
}
