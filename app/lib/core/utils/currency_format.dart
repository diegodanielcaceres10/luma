import 'package:intl/intl.dart';

/// Formatea un monto según convención española: '2.480,75 €'.
/// [currencyCode] es el código ISO de moneda a usar (hoy viene de
/// [AccountViewModel.primaryCurrency], que a su vez refleja la moneda
/// elegida en Preferencias — ver [PreferencesViewModel.setCurrencyCode]).
String formatCurrency(double amount, String currencyCode) {
  final format = NumberFormat.currency(locale: 'es_ES', name: currencyCode);
  return format.format(amount);
}
