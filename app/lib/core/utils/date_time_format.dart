import 'package:intl/intl.dart';

/// Formats a date with time using Spanish conventions: '12 oct. 2026, 14:30'.
/// Converts to the device's local time zone first.
String formatDateTime(DateTime value) {
  return DateFormat('d MMM. yyyy, HH:mm', 'es').format(value.toLocal());
}
