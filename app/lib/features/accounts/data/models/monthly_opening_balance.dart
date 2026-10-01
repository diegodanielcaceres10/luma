/// Opening balance of one account for one month, as stored in
/// `monthly_account_balances`.
class MonthlyOpeningBalance {
  final int month;
  final int year;
  final double openingBalance;

  const MonthlyOpeningBalance({
    required this.month,
    required this.year,
    required this.openingBalance,
  });

  factory MonthlyOpeningBalance.fromMap(Map<String, dynamic> map) {
    return MonthlyOpeningBalance(
      month: map['month'] as int,
      year: map['year'] as int,
      openingBalance: (map['opening_balance'] as num).toDouble(),
    );
  }
}

/// How much [currentBalance] moved since the opening balance of
/// [month]/[year], rounded to cents. Null when [history] has no row for
/// that month, since there is nothing to compare against.
double? monthVariation({
  required double currentBalance,
  required List<MonthlyOpeningBalance> history,
  required int month,
  required int year,
}) {
  for (final entry in history) {
    if (entry.month == month && entry.year == year) {
      return ((currentBalance - entry.openingBalance) * 100).round() / 100;
    }
  }
  return null;
}
