import '../../data/models/transaction_entry.dart' show TransactionCategory;
import 'transaction_view_model.dart' show CategoryTotal;

/// Derived figures of the statistics for one month.
///
/// Shared by the statistics screen and its PDF export so both always show
/// the same numbers.
class TransactionsStatisticsReport {
  static const _categorizedLabel = 'Categorizados';
  static const _uncategorizedLabel = 'No categorizados';
  static const _undeclaredLabel = 'No declarados';

  final double income;

  /// Includes the uncontrolled adjustment when it is an expense.
  final double expenses;

  /// Includes the uncontrolled adjustment, whether income or expense.
  final double netResult;

  /// Signed sum of uncontrolled adjustments (negative is an expense).
  final double uncontrolledTotal;

  /// Expenses by category, uncategorized entries included.
  final List<CategoryTotal> breakdown;

  final double categorizedTotal;

  /// Categorized entries only, with percents recalculated against
  /// [categorizedTotal] so the donut and legend sum to 100%.
  final List<CategoryTotal> categorizedBreakdown;

  /// Categorized, uncategorized and undeclared buckets, skipping empty ones.
  final List<CategoryTotal> expenseTypeBreakdown;
  final double expenseTypeTotal;

  const TransactionsStatisticsReport._({
    required this.income,
    required this.expenses,
    required this.netResult,
    required this.uncontrolledTotal,
    required this.breakdown,
    required this.categorizedTotal,
    required this.categorizedBreakdown,
    required this.expenseTypeBreakdown,
    required this.expenseTypeTotal,
  });

  /// [expenses] and [netResult] are the raw month figures, without the
  /// uncontrolled adjustment.
  factory TransactionsStatisticsReport.fromTotals({
    required double income,
    required double expenses,
    required double netResult,
    required double uncontrolledTotal,
    required List<CategoryTotal> breakdown,
  }) {
    final categorizedEntries =
        breakdown.where((c) => c.category.id != null).toList();
    final categorizedTotal =
        categorizedEntries.fold<double>(0, (sum, c) => sum + c.amount);
    final uncategorizedTotal = breakdown
        .where((c) => c.category.id == null)
        .fold<double>(0, (sum, c) => sum + c.amount);
    final undeclaredTotal = uncontrolledTotal < 0 ? -uncontrolledTotal : 0.0;

    final categorizedBreakdown = categorizedEntries
        .map((c) => CategoryTotal(
              category: c.category,
              amount: c.amount,
              percent: categorizedTotal > 0
                  ? (c.amount / categorizedTotal) * 100
                  : 0,
            ))
        .toList();

    final expenseTypeTotal =
        categorizedTotal + uncategorizedTotal + undeclaredTotal;
    double percentOf(double amount) =>
        expenseTypeTotal > 0 ? (amount / expenseTypeTotal) * 100 : 0;

    final expenseTypeBreakdown = [
      if (categorizedTotal > 0)
        CategoryTotal(
          category: const TransactionCategory(
            name: _categorizedLabel,
            color: '#4CBB7A',
          ),
          amount: categorizedTotal,
          percent: percentOf(categorizedTotal),
        ),
      if (uncategorizedTotal > 0)
        CategoryTotal(
          category: const TransactionCategory(
            name: _uncategorizedLabel,
            color: '#F59E0B',
          ),
          amount: uncategorizedTotal,
          percent: percentOf(uncategorizedTotal),
        ),
      if (undeclaredTotal > 0)
        CategoryTotal(
          category: const TransactionCategory(
            name: _undeclaredLabel,
            color: '#EF6F5B',
          ),
          amount: undeclaredTotal,
          percent: percentOf(undeclaredTotal),
        ),
    ];

    return TransactionsStatisticsReport._(
      income: income,
      expenses: expenses + undeclaredTotal,
      netResult: netResult + uncontrolledTotal,
      uncontrolledTotal: uncontrolledTotal,
      breakdown: breakdown,
      categorizedTotal: categorizedTotal,
      categorizedBreakdown: categorizedBreakdown,
      expenseTypeBreakdown: expenseTypeBreakdown,
      expenseTypeTotal: expenseTypeTotal,
    );
  }

  bool get hasUncontrolledTotal => uncontrolledTotal.abs() >= 0.005;
  bool get isUncontrolledExpense => uncontrolledTotal < 0;
}
