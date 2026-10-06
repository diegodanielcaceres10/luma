import '../../data/models/transaction_entry.dart';

class CategoryTotal {
  final TransactionCategory category;
  final double amount;
  final double percent;

  const CategoryTotal({
    required this.category,
    required this.amount,
    required this.percent,
  });
}

/// Pure calculations over transactions, kept apart from the view model so
/// they do not depend on its state.
class TransactionTotals {
  TransactionTotals._();

  static double sumByType(List<TransactionEntry> entries, String type) {
    return entries
        .where((t) => t.type == type && !t.isTransfer)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  static double? percentChange(double previous, double current) {
    if (previous == 0) return null;
    return ((current - previous) / previous.abs()) * 100;
  }

  /// Expenses grouped by category (largest first) with their share of the
  /// total. Transfers are excluded.
  static List<CategoryTotal> breakdownOf(List<TransactionEntry> entries) {
    final expenses = entries.where((t) => t.type == 'expense' && !t.isTransfer);
    final Map<String, double> totals = {};
    final Map<String, TransactionCategory> categories = {};

    for (final t in expenses) {
      final key = t.category.id ?? t.category.name;
      totals[key] = (totals[key] ?? 0) + t.amount;
      categories[key] = t.category;
    }

    final total = sumByType(entries, 'expense');
    final list = totals.entries.map((e) {
      return CategoryTotal(
        category: categories[e.key]!,
        amount: e.value,
        percent: total > 0 ? (e.value / total) * 100 : 0,
      );
    }).toList();

    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }
}
