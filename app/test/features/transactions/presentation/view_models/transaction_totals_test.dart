import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/presentation/view_models/transaction_totals.dart';

TransactionEntry entry({
  String type = 'expense',
  double amount = 10,
  TransactionCategory category = const TransactionCategory(
    id: 'c1',
    name: 'Comida',
  ),
  bool isTransfer = false,
}) {
  return TransactionEntry(
    id: 't-$type-$amount-${category.id ?? category.name}',
    type: type,
    amount: amount,
    date: DateTime(2026, 10, 9),
    category: category,
    account: const TransactionAccount(id: 'a1', name: 'Santander'),
    isTransfer: isTransfer,
  );
}

void main() {
  group('TransactionTotals.sumByType', () {
    test('is zero for an empty list', () {
      expect(TransactionTotals.sumByType(const [], 'expense'), 0);
    });

    test('sums only the requested type', () {
      final entries = [
        entry(type: 'expense', amount: 10),
        entry(type: 'expense', amount: 5.5),
        entry(type: 'income', amount: 100),
      ];

      expect(TransactionTotals.sumByType(entries, 'expense'), 15.5);
      expect(TransactionTotals.sumByType(entries, 'income'), 100);
    });

    test('ignores transfers', () {
      final entries = [
        entry(type: 'expense', amount: 10),
        entry(type: 'expense', amount: 500, isTransfer: true),
        entry(type: 'income', amount: 500, isTransfer: true),
      ];

      expect(TransactionTotals.sumByType(entries, 'expense'), 10);
      expect(TransactionTotals.sumByType(entries, 'income'), 0);
    });

    test('is zero for an unknown type', () {
      expect(
        TransactionTotals.sumByType([entry(amount: 10)], 'transfer'),
        0,
      );
    });
  });

  group('TransactionTotals.percentChange', () {
    test('is null when there is no previous amount to compare with', () {
      expect(TransactionTotals.percentChange(0, 50), isNull);
      expect(TransactionTotals.percentChange(0, 0), isNull);
    });

    test('reports increases and decreases', () {
      expect(TransactionTotals.percentChange(100, 150), 50);
      expect(TransactionTotals.percentChange(100, 50), -50);
      expect(TransactionTotals.percentChange(100, 100), 0);
    });

    test('uses the absolute value of the previous amount', () {
      expect(TransactionTotals.percentChange(-100, -50), 50);
    });
  });

  group('TransactionTotals.breakdownOf', () {
    const food = TransactionCategory(id: 'c1', name: 'Comida');
    const rent = TransactionCategory(id: 'c2', name: 'Alquiler');

    test('is empty for an empty list', () {
      expect(TransactionTotals.breakdownOf(const []), isEmpty);
    });

    test('is empty when there are only income and transfers', () {
      final entries = [
        entry(type: 'income', amount: 100),
        entry(type: 'expense', amount: 50, isTransfer: true),
      ];

      expect(TransactionTotals.breakdownOf(entries), isEmpty);
    });

    test('adds up expenses of the same category', () {
      final result = TransactionTotals.breakdownOf([
        entry(amount: 10, category: food),
        entry(amount: 15, category: food),
      ]);

      expect(result, hasLength(1));
      expect(result.single.category.id, 'c1');
      expect(result.single.amount, 25);
      expect(result.single.percent, 100);
    });

    test('sorts from the largest to the smallest amount', () {
      final result = TransactionTotals.breakdownOf([
        entry(amount: 10, category: food),
        entry(amount: 90, category: rent),
      ]);

      expect(result.map((r) => r.category.id), ['c2', 'c1']);
    });

    test('percents are shares of the total and add up to 100', () {
      final result = TransactionTotals.breakdownOf([
        entry(amount: 25, category: food),
        entry(amount: 75, category: rent),
      ]);

      expect(result.map((r) => r.percent), [75, 25]);
      expect(result.fold<double>(0, (sum, r) => sum + r.percent), 100);
    });

    test('leaves out income and transfers', () {
      final result = TransactionTotals.breakdownOf([
        entry(amount: 20, category: food),
        entry(type: 'income', amount: 1000, category: rent),
        entry(amount: 300, category: rent, isTransfer: true),
      ]);

      expect(result, hasLength(1));
      expect(result.single.category.id, 'c1');
      expect(result.single.percent, 100);
    });

    test('keeps categories without id apart when their names differ', () {
      const sin = TransactionCategory(name: 'Sin categoría');
      const otra = TransactionCategory(name: 'Otra');

      final result = TransactionTotals.breakdownOf([
        entry(amount: 10, category: sin),
        entry(amount: 30, category: otra),
      ]);

      expect(result.map((r) => r.category.name), ['Otra', 'Sin categoría']);
    });

    test('groups categories without id by name', () {
      const sin = TransactionCategory(name: 'Sin categoría');

      final result = TransactionTotals.breakdownOf([
        entry(amount: 10, category: sin),
        entry(amount: 5, category: sin),
      ]);

      expect(result, hasLength(1));
      expect(result.single.amount, 15);
    });

    test('does not divide by zero when expenses add up to zero', () {
      final result = TransactionTotals.breakdownOf([
        entry(amount: 0, category: food),
      ]);

      expect(result, hasLength(1));
      expect(result.single.percent, 0);
      expect(result.single.percent.isNaN, isFalse);
    });
  });
}
