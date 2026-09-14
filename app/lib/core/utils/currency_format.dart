import 'package:intl/intl.dart';

/// Formatea un monto según convención española: '2.480,75 €'.
/// [currencyCode] es el código ISO guardado en accounts.currency (ej. 'EUR', 'USD').
String formatCurrency(double amount, String currencyCode) {
  final format = NumberFormat.currency(locale: 'es_ES', name: currencyCode);
  return format.format(amount);
}
