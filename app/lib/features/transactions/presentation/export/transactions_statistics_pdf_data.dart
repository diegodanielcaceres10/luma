import '../../data/models/transaction_entry.dart' show TransactionEntry;
import '../view_models/transactions_statistics_report.dart';

/// Snapshot of the statistics for one month, taken at export time so the
/// PDF does not change if the user switches months meanwhile.
class TransactionsStatisticsScreenPdfData {
  final DateTime month;

  final String monthLabel;
  final String currency;
  final TransactionsStatisticsReport report;

  // The PDF is only generated for closed months, so the change vs. the
  // previous month is always comparable.
  final double? incomeChangePercent;
  final double? expenseChangePercent;
  final double? netChangePercent;

  /// Movements of the month, newest first. When not null the PDF is the
  /// extended report: the summary on the first page and the movements from
  /// the second page on.
  final List<TransactionEntry>? movements;

  const TransactionsStatisticsScreenPdfData({
    required this.month,
    required this.monthLabel,
    required this.currency,
    required this.report,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
    required this.netChangePercent,
    this.movements,
  });

  String get fileName {
    final suffix = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    return movements == null
        ? 'luma-estadisticas-$suffix.pdf'
        : 'luma-estadisticas-completo-$suffix.pdf';
  }
}
