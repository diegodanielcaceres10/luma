import '../../transactions/data/models/transaction_entry.dart';

/// Number of months shown in the category trend, current month included.
const int kCategoryTrendMonths = 3;

class MonthTotal {
  /// First day of the month.
  final DateTime month;
  final double total;

  const MonthTotal({required this.month, required this.total});
}

class CategoryTrend {
  /// Oldest first; the last item is the current (in-progress) month.
  final List<MonthTotal> months;

  /// Average of the completed months before the current one.
  final double previousMonthsAverage;

  /// Current month so far versus the same days of the previous month.
  /// Null when the previous month has nothing to compare against.
  final double? changePercent;

  const CategoryTrend({
    required this.months,
    required this.previousMonthsAverage,
    required this.changePercent,
  });

  bool get isEmpty => months.every((m) => m.total == 0);
}

/// First day of the oldest month in the trend window for [today].
DateTime categoryTrendStart(DateTime today) =>
    DateTime(today.year, today.month - (kCategoryTrendMonths - 1), 1);

/// Builds the trend from the entries of a single category.
CategoryTrend buildCategoryTrend({
  required List<TransactionEntry> entries,
  required DateTime today,
}) {
  final spending = entries.where((e) => !e.isTransfer).toList();

  double sumOf(DateTime month, {int? upToDay}) {
    var total = 0.0;
    for (final entry in spending) {
      if (entry.date.year != month.year || entry.date.month != month.month) {
        continue;
      }
      if (upToDay != null && entry.date.day > upToDay) continue;
      total += entry.amount;
    }
    return total;
  }

  final start = categoryTrendStart(today);
  final months = [
    for (var i = 0; i < kCategoryTrendMonths; i++)
      MonthTotal(
        month: DateTime(start.year, start.month + i, 1),
        total: sumOf(DateTime(start.year, start.month + i, 1)),
      ),
  ];

  final completed = months.sublist(0, months.length - 1);
  final average = completed.isEmpty
      ? 0.0
      : completed.fold<double>(0, (sum, m) => sum + m.total) /
          completed.length;

  final currentSoFar = sumOf(months.last.month, upToDay: today.day);
  final previousSamePeriod = sumOf(
    months[months.length - 2].month,
    upToDay: today.day,
  );
  final change = previousSamePeriod == 0
      ? null
      : (currentSoFar - previousSamePeriod) / previousSamePeriod * 100;

  return CategoryTrend(
    months: months,
    previousMonthsAverage: average,
    changePercent: change,
  );
}
