import '../data/models/monthly_opening_balance.dart';

/// Number of months shown in the account trend, current month included.
const int kAccountTrendMonths = 3;

class AccountMonth {
  /// First day of the month.
  final DateTime month;

  /// Opening balance of the month, if it was recorded.
  final double? opening;

  /// How much the balance moved during the month; null when either end
  /// of the month is unknown.
  final double? change;

  const AccountMonth({
    required this.month,
    required this.opening,
    required this.change,
  });
}

class AccountTrend {
  /// Oldest first; the last item is the current (in-progress) month.
  final List<AccountMonth> months;

  /// Current balance minus the oldest opening balance in the window; null
  /// when there is no opening balance at all.
  final double? totalChange;

  const AccountTrend({required this.months, required this.totalChange});

  bool get isEmpty => months.every((m) => m.change == null);
}

double _roundToCents(double value) => (value * 100).round() / 100;

/// Builds the trend from the opening balances of an account.
///
/// A completed month moved from its opening balance to the next month's;
/// the current one moved from its opening balance to [currentBalance].
AccountTrend buildAccountTrend({
  required List<MonthlyOpeningBalance> history,
  required double currentBalance,
  required DateTime today,
}) {
  final start =
      DateTime(today.year, today.month - (kAccountTrendMonths - 1), 1);
  final starts = [
    for (var i = 0; i < kAccountTrendMonths; i++)
      DateTime(start.year, start.month + i, 1),
  ];

  double? openingOf(DateTime month) {
    for (final entry in history) {
      if (entry.month == month.month && entry.year == month.year) {
        return entry.openingBalance;
      }
    }
    return null;
  }

  final openings = [for (final month in starts) openingOf(month)];

  final months = <AccountMonth>[];
  for (var i = 0; i < starts.length; i++) {
    final opening = openings[i];
    final end = i == starts.length - 1 ? currentBalance : openings[i + 1];
    months.add(
      AccountMonth(
        month: starts[i],
        opening: opening,
        change: opening == null || end == null
            ? null
            : _roundToCents(end - opening),
      ),
    );
  }

  final oldestOpening = openings.firstWhere(
    (opening) => opening != null,
    orElse: () => null,
  );

  return AccountTrend(
    months: months,
    totalChange: oldestOpening == null
        ? null
        : _roundToCents(currentBalance - oldestOpening),
  );
}
