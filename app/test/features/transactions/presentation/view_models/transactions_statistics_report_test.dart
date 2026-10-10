import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/presentation/view_models/transaction_totals.dart';
import 'package:luma/features/transactions/presentation/view_models/transactions_statistics_report.dart';

CategoryTotal total(String name, double amount, {String? id}) {
  return CategoryTotal(
    category: TransactionCategory(id: id, name: name),
    amount: amount,
    percent: 0,
  );
}

TransactionsStatisticsReport report({
  double income = 1000,
  double expenses = 100,
  double netResult = 900,
  double uncontrolledTotal = 0,
  List<CategoryTotal> breakdown = const [],
}) {
  return TransactionsStatisticsReport.fromTotals(
    income: income,
    expenses: expenses,
    netResult: netResult,
    uncontrolledTotal: uncontrolledTotal,
    breakdown: breakdown,
  );
}

double sumOfPercents(List<CategoryTotal> list) =>
    list.fold<double>(0, (sum, c) => sum + c.percent);

void main() {
  group('uncontrolled adjustment', () {
    test('without it, the raw figures pass through', () {
      final r = report();

      expect(r.income, 1000);
      expect(r.expenses, 100);
      expect(r.netResult, 900);
      expect(r.uncontrolledTotal, 0);
      expect(r.hasUncontrolledTotal, isFalse);
      expect(r.isUncontrolledExpense, isFalse);
    });

    test('an expense adds to the expenses and lowers the net result', () {
      final r = report(uncontrolledTotal: -30);

      expect(r.expenses, 130);
      expect(r.netResult, 870);
      expect(r.income, 1000);
      expect(r.hasUncontrolledTotal, isTrue);
      expect(r.isUncontrolledExpense, isTrue);
    });

    test('an income raises the net result and leaves the expenses alone', () {
      final r = report(uncontrolledTotal: 30);

      expect(r.expenses, 100);
      expect(r.netResult, 930);
      expect(r.hasUncontrolledTotal, isTrue);
      expect(r.isUncontrolledExpense, isFalse);
    });

    test('amounts under half a cent do not count as an adjustment', () {
      expect(report(uncontrolledTotal: 0.004).hasUncontrolledTotal, isFalse);
      expect(report(uncontrolledTotal: -0.004).hasUncontrolledTotal, isFalse);
    });

    test('half a cent or more does count, in either direction', () {
      expect(report(uncontrolledTotal: 0.005).hasUncontrolledTotal, isTrue);
      expect(report(uncontrolledTotal: -0.005).hasUncontrolledTotal, isTrue);
    });
  });

  group('categorizedBreakdown', () {
    final breakdown = [
      total('Comida', 60, id: 'c1'),
      total('Alquiler', 20, id: 'c2'),
      total('Sin categoría', 20),
    ];

    test('keeps only categories that have an id', () {
      final r = report(breakdown: breakdown);

      expect(r.categorizedBreakdown.map((c) => c.category.id), ['c1', 'c2']);
      expect(r.categorizedBreakdown.map((c) => c.amount), [60, 20]);
      expect(r.categorizedTotal, 80);
    });

    test('recalculates percents against the categorized total', () {
      final r = report(breakdown: breakdown);

      expect(r.categorizedBreakdown.map((c) => c.percent), [75, 25]);
      expect(sumOfPercents(r.categorizedBreakdown), 100);
    });

    test('is empty when nothing is categorized', () {
      final r = report(breakdown: [total('Sin categoría', 20)]);

      expect(r.categorizedBreakdown, isEmpty);
      expect(r.categorizedTotal, 0);
    });

    test('does not divide by zero when categorized amounts are zero', () {
      final r = report(breakdown: [total('Comida', 0, id: 'c1')]);

      expect(r.categorizedBreakdown.single.percent, 0);
      expect(r.categorizedBreakdown.single.percent.isNaN, isFalse);
    });

    test('keeps the original breakdown untouched', () {
      final r = report(breakdown: breakdown);

      expect(r.breakdown, hasLength(3));
      expect(identical(r.breakdown[2], breakdown[2]), isTrue);
    });
  });

  group('expenseTypeBreakdown', () {
    final breakdown = [
      total('Comida', 60, id: 'c1'),
      total('Alquiler', 20, id: 'c2'),
      total('Sin categoría', 20),
    ];

    test('lists categorized, uncategorized and undeclared in that order', () {
      final r = report(breakdown: breakdown, uncontrolledTotal: -20);

      expect(
        r.expenseTypeBreakdown.map((c) => c.category.name),
        ['Categorizados', 'No categorizados', 'No declarados'],
      );
      expect(r.expenseTypeBreakdown.map((c) => c.amount), [80, 20, 20]);
      expect(r.expenseTypeTotal, 120);
    });

    test('percents are shares of the whole and add up to 100', () {
      final r = report(breakdown: breakdown, uncontrolledTotal: -20);

      expect(sumOfPercents(r.expenseTypeBreakdown), closeTo(100, 1e-9));
      expect(r.expenseTypeBreakdown.first.percent, closeTo(200 / 3, 1e-9));
    });

    test('skips the buckets that are empty', () {
      final r = report(breakdown: [total('Comida', 40, id: 'c1')]);

      expect(r.expenseTypeBreakdown, hasLength(1));
      expect(r.expenseTypeBreakdown.single.category.name, 'Categorizados');
      expect(r.expenseTypeBreakdown.single.percent, 100);
      expect(r.expenseTypeTotal, 40);
    });

    test('an income adjustment is not an undeclared expense', () {
      final r = report(
        breakdown: [total('Comida', 40, id: 'c1')],
        uncontrolledTotal: 25,
      );

      expect(
        r.expenseTypeBreakdown.map((c) => c.category.name),
        ['Categorizados'],
      );
      expect(r.expenseTypeTotal, 40);
    });

    test('can hold only the undeclared bucket', () {
      final r = report(uncontrolledTotal: -50);

      expect(r.categorizedTotal, 0);
      expect(r.expenseTypeBreakdown, hasLength(1));
      expect(r.expenseTypeBreakdown.single.category.name, 'No declarados');
      expect(r.expenseTypeBreakdown.single.amount, 50);
      expect(r.expenseTypeBreakdown.single.percent, 100);
      expect(r.expenseTypeTotal, 50);
    });

    test('is empty when there are no expenses at all', () {
      final r = report();

      expect(r.expenseTypeBreakdown, isEmpty);
      expect(r.expenseTypeTotal, 0);
      expect(r.categorizedBreakdown, isEmpty);
      expect(r.breakdown, isEmpty);
    });
  });
}
