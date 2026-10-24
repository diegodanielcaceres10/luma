import '../../../categories/data/models/category.dart';
import '../../../invoices/data/models/invoice.dart';
import '../../../services/data/models/service.dart';
import '../../../transactions/data/models/transaction_entry.dart';
import '../../../transactions/presentation/view_models/transaction_totals.dart';
import '../../../transactions/presentation/view_models/transactions_statistics_report.dart';

/// How a change reads for the user: expenses going down is favorable,
/// income going up is favorable.
enum ComparisonTone { favorable, unfavorable, neutral }

/// One concept (a summary figure, a category or a service) in both months.
///
/// A null [before] or [after] means the month has no data for the concept;
/// it is not the same as zero.
class ComparisonRow {
  final String id;
  final String label;
  final String? colorHex;
  final double? before;
  final double? after;

  /// `after - before`; null when either month has no data.
  final double? difference;

  /// Null when [before] is zero or either month has no data.
  final double? percentChange;

  /// The concept had nothing in [before] and has an amount in [after].
  final bool isNew;
  final ComparisonTone tone;

  /// Current monthly budget of the category, when it has one.
  final double? budget;

  const ComparisonRow({
    required this.id,
    required this.label,
    this.colorHex,
    this.before,
    this.after,
    this.difference,
    this.percentChange,
    this.isNew = false,
    this.tone = ComparisonTone.neutral,
    this.budget,
  });

  factory ComparisonRow.compare({
    required String id,
    required String label,
    String? colorHex,
    required double? before,
    required double? after,
    required bool higherIsFavorable,
    double? budget,
  }) {
    // Checked inline: Dart does not promote through a separate bool.
    final difference =
        before != null && after != null ? after - before : null;

    return ComparisonRow(
      id: id,
      label: label,
      colorHex: colorHex,
      before: before,
      after: after,
      difference: difference,
      percentChange: before != null && after != null
          ? TransactionTotals.percentChange(before, after)
          : null,
      isNew: before != null && after != null && before == 0 && after > 0,
      tone: _toneOf(difference, higherIsFavorable),
      budget: budget,
    );
  }

  static ComparisonTone _toneOf(double? difference, bool higherIsFavorable) {
    if (difference == null || difference.abs() < _epsilon) {
      return ComparisonTone.neutral;
    }
    return (difference > 0) == higherIsFavorable
        ? ComparisonTone.favorable
        : ComparisonTone.unfavorable;
  }
}

/// Raw data of one month, as loaded by the view model.
class MonthSnapshot {
  /// First day of the month.
  final DateTime month;
  final List<TransactionEntry> entries;

  /// Signed sum of uncontrolled adjustments (negative is an expense).
  final double uncontrolledTotal;

  const MonthSnapshot({
    required this.month,
    required this.entries,
    required this.uncontrolledTotal,
  });
}

const _epsilon = 0.005;
const _uncategorizedId = 'uncategorized';
const _uncategorizedLabel = 'Sin categoría';
const _unknownServiceLabel = 'Servicio desconocido';

bool _isZero(double? value) => value == null || value.abs() < _epsilon;

/// Side by side figures of two months. Pure: every number comes from the
/// same [TransactionsStatisticsReport] the statistics screen uses, so both
/// screens always agree.
class MonthComparison {
  final List<ComparisonRow> summary;
  final List<ComparisonRow> categories;
  final List<ComparisonRow> services;

  const MonthComparison._({
    required this.summary,
    required this.categories,
    required this.services,
  });

  /// Nothing to compare: no movements in either month and no invoices.
  bool get isEmpty =>
      categories.isEmpty &&
      services.isEmpty &&
      summary.every((row) => _isZero(row.before) && _isZero(row.after));

  factory MonthComparison.compute({
    required MonthSnapshot before,
    required MonthSnapshot after,
    required List<Category> categories,
    required List<Service> services,
    required List<Invoice> invoices,
  }) {
    final beforeReport = _reportOf(before);
    final afterReport = _reportOf(after);

    return MonthComparison._(
      summary: _summaryRows(beforeReport, afterReport),
      categories: _categoryRows(beforeReport, afterReport, categories),
      services: _serviceRows(before.month, after.month, services, invoices),
    );
  }

  static TransactionsStatisticsReport _reportOf(MonthSnapshot snapshot) {
    final income = TransactionTotals.sumByType(snapshot.entries, 'income');
    final expenses = TransactionTotals.sumByType(snapshot.entries, 'expense');
    return TransactionsStatisticsReport.fromTotals(
      income: income,
      expenses: expenses,
      netResult: income - expenses,
      uncontrolledTotal: snapshot.uncontrolledTotal,
      breakdown: TransactionTotals.breakdownOf(snapshot.entries),
    );
  }

  static List<ComparisonRow> _summaryRows(
    TransactionsStatisticsReport before,
    TransactionsStatisticsReport after,
  ) {
    // Adding zero turns a negative zero into a plain zero.
    final beforeUndeclared = -before.uncontrolledTotal + 0.0;
    final afterUndeclared = -after.uncontrolledTotal + 0.0;

    return [
      ComparisonRow.compare(
        id: 'income',
        label: 'Ingresos',
        before: before.income,
        after: after.income,
        higherIsFavorable: true,
      ),
      ComparisonRow.compare(
        id: 'expenses',
        label: 'Gastos',
        before: before.expenses,
        after: after.expenses,
        higherIsFavorable: false,
      ),
      ComparisonRow.compare(
        id: 'balance',
        label: 'Balance',
        before: before.netResult,
        after: after.netResult,
        higherIsFavorable: true,
      ),
      if (!_isZero(beforeUndeclared) || !_isZero(afterUndeclared))
        ComparisonRow.compare(
          id: 'undeclared',
          label: 'Sin declarar',
          before: beforeUndeclared,
          after: afterUndeclared,
          higherIsFavorable: false,
        ),
    ];
  }

  static List<ComparisonRow> _categoryRows(
    TransactionsStatisticsReport before,
    TransactionsStatisticsReport after,
    List<Category> categories,
  ) {
    final beforeTotals = _totalsByCategory(before);
    final afterTotals = _totalsByCategory(after);
    final budgets = {
      for (final c in categories)
        if (c.hasBudget && c.budgetAmount != null) c.id: c.budgetAmount!,
    };

    final ids = {...beforeTotals.keys, ...afterTotals.keys};
    final rows = <ComparisonRow>[];
    for (final id in ids) {
      final beforeAmount = beforeTotals[id]?.amount ?? 0;
      final afterAmount = afterTotals[id]?.amount ?? 0;
      if (_isZero(beforeAmount) && _isZero(afterAmount)) continue;

      final category = (afterTotals[id] ?? beforeTotals[id])!;
      rows.add(
        ComparisonRow.compare(
          id: id,
          label: id == _uncategorizedId ? _uncategorizedLabel : category.name,
          colorHex: category.color,
          before: beforeAmount,
          after: afterAmount,
          higherIsFavorable: false,
          budget: budgets[id],
        ),
      );
    }

    rows.sort((a, b) {
      final byChange = b.difference!.abs().compareTo(a.difference!.abs());
      return byChange != 0 ? byChange : a.label.compareTo(b.label);
    });
    return rows;
  }

  /// Expenses by category id. Entries without a category share one bucket,
  /// whatever placeholder name the backend gave them.
  static Map<String, _CategoryAmount> _totalsByCategory(
    TransactionsStatisticsReport report,
  ) {
    final totals = <String, _CategoryAmount>{};
    for (final item in report.breakdown) {
      final id = item.category.id ?? _uncategorizedId;
      final current = totals[id];
      totals[id] = _CategoryAmount(
        name: item.category.name,
        color: item.category.color,
        amount: (current?.amount ?? 0) + item.amount,
      );
    }
    return totals;
  }

  static List<ComparisonRow> _serviceRows(
    DateTime beforeMonth,
    DateTime afterMonth,
    List<Service> services,
    List<Invoice> invoices,
  ) {
    final beforeTotals = _invoiceTotals(invoices, beforeMonth);
    final afterTotals = _invoiceTotals(invoices, afterMonth);
    final names = {for (final s in services) s.id: s.name};

    final ids = {...beforeTotals.keys, ...afterTotals.keys};
    final rows = <ComparisonRow>[];
    for (final id in ids) {
      final beforeAmount = beforeTotals[id];
      final afterAmount = afterTotals[id];
      if (_isZero(beforeAmount) && _isZero(afterAmount)) continue;

      rows.add(
        ComparisonRow.compare(
          id: id,
          label: names[id] ?? _unknownServiceLabel,
          before: beforeAmount,
          after: afterAmount,
          higherIsFavorable: false,
        ),
      );
    }

    // Rows with both months first, by size of the change.
    rows.sort((a, b) {
      final aDiff = a.difference;
      final bDiff = b.difference;
      if (aDiff != null && bDiff != null) {
        final byChange = bDiff.abs().compareTo(aDiff.abs());
        if (byChange != 0) return byChange;
      } else if (aDiff != null) {
        return -1;
      } else if (bDiff != null) {
        return 1;
      }
      return a.label.compareTo(b.label);
    });
    return rows;
  }

  /// Sum of the non-cancelled invoices of [month], by service id.
  static Map<String, double> _invoiceTotals(
    List<Invoice> invoices,
    DateTime month,
  ) {
    final totals = <String, double>{};
    for (final invoice in invoices) {
      if (invoice.cancelled ||
          invoice.month != month.month ||
          invoice.year != month.year) {
        continue;
      }
      totals[invoice.serviceId] =
          (totals[invoice.serviceId] ?? 0) + invoice.amount;
    }
    return totals;
  }
}

class _CategoryAmount {
  final String name;
  final String? color;
  final double amount;

  const _CategoryAmount({
    required this.name,
    required this.color,
    required this.amount,
  });
}
