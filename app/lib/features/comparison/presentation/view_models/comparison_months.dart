import '../../../transactions/presentation/view_models/transactions_filters.dart';

/// The two months a comparison opens with, read from and written to the
/// `/statistics/compare` URL.
class ComparisonMonths {
  static const _path = '/statistics/compare';

  /// First day of the "before" month.
  final DateTime before;

  /// First day of the "after" month.
  final DateTime after;

  const ComparisonMonths({required this.before, required this.after});

  /// [to] defaults to the current month and [from] to the month before [to].
  /// Values that are not a `YYYY-MM` month fall back to those defaults, so a
  /// hand-edited URL never breaks the screen.
  factory ComparisonMonths.fromQuery({String? from, String? to}) {
    final after = _parse(to) ?? TransactionsFilters.currentMonth();
    final before = _parse(from) ?? DateTime(after.year, after.month - 1);
    return ComparisonMonths(before: before, after: after);
  }

  /// Location that opens the comparison of [afterMonth] against the month
  /// before it. The current month is the default, so it is left out.
  static String locationFor(DateTime afterMonth) {
    final after = DateTime(afterMonth.year, afterMonth.month);
    final before = DateTime(after.year, after.month - 1);
    final to = TransactionsFilters.monthQueryValue(after);

    return Uri(
      path: _path,
      queryParameters: {
        'from': _format(before),
        if (to != null) 'to': to,
      },
    ).toString();
  }

  static DateTime? _parse(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return null;
    return DateTime(int.parse(match.group(1)!), month);
  }

  static String _format(DateTime month) {
    final mm = month.month.toString().padLeft(2, '0');
    return '${month.year}-$mm';
  }
}
