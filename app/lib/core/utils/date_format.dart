import 'package:intl/intl.dart';

/// How dates are shown across the app. Chosen in Preferences and stored by
/// [name], so do not rename a value without migrating the stored one.
enum DateDisplayFormat {
  dayMonthYear('dd/MM/yyyy'),
  monthDayYear('MM/dd/yyyy'),
  yearMonthDay('yyyy-MM-dd'),
  text('d MMM yyyy');

  final String pattern;

  const DateDisplayFormat(this.pattern);

  static const defaultFormat = DateDisplayFormat.text;

  /// Restores a stored [name]; a missing or unknown one gives [defaultFormat].
  static DateDisplayFormat parse(String? name) =>
      values.asNameMap()[name] ?? defaultFormat;
}

/// Formats [date] in [format] using Spanish month names ('31 dic 2026').
String formatDate(
  DateTime date, [
  DateDisplayFormat format = DateDisplayFormat.defaultFormat,
]) {
  return DateFormat(format.pattern, 'es').format(date);
}
