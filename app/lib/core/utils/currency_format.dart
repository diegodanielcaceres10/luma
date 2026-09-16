import 'package:intl/intl.dart';

/// Formatea un monto según convención española: '2.480,75 €'.
/// [currencyCode] es el código ISO de moneda a usar (hoy viene de
/// [AccountViewModel.primaryCurrency], un valor fijo hasta que exista
/// una moneda configurable a nivel usuario).
String formatCurrency(double amount, String currencyCode) {
  final format = NumberFormat.currency(locale: 'es_ES', name: currencyCode);
  return format.format(amount);
}
