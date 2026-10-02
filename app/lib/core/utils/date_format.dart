import 'package:intl/intl.dart';

import 'app_clock.dart';

/// How dates are shown across the app: '25/10/2026'.
const String kDatePattern = 'dd/MM/yyyy';

/// Date with time, for values that carry a moment: '25/10/2026 14:30'.
const String kDateTimePattern = 'dd/MM/yyyy HH:mm';

/// Formats [date] as dd/MM/yyyy. The value is formatted as given: pass dates
/// that are already local (see `asLocal`).
String formatDate(DateTime date) => DateFormat(kDatePattern).format(date);

/// Formats [value] as dd/MM/yyyy HH:mm, converting to the local time zone
/// first.
String formatDateTime(DateTime value) =>
    DateFormat(kDateTimePattern).format(asLocal(value));

/// Formats [date] as yyyy-MM-dd, the format the database expects for `date`
/// columns. Not meant to be shown to the user.
String formatDbDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
