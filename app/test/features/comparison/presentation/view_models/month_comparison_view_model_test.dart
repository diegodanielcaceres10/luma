import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/comparison/presentation/view_models/month_comparison_view_model.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';

import '../../../../helpers/fakes.dart';

TransactionEntry entry(String id, double amount) {
  return TransactionEntry(
    id: id,
    type: 'expense',
    amount: amount,
    date: DateTime(2026, 9, 10),
    category: const TransactionCategory(name: 'Sin categoría'),
    account: const TransactionAccount(name: 'Cuenta'),
  );
}

int index(int year, int month) => year * 12 + month;

void main() {
  late FakeTransactionRepository transactions;
  late FakeMonthlyBalanceRepository monthlyBalances;
  late MonthComparisonViewModel viewModel;

  final august = DateTime(2026, 8);
  final september = DateTime(2026, 9);
  final october = DateTime(2026, 10);

  setUp(() {
    transactions = FakeTransactionRepository();
    monthlyBalances = FakeMonthlyBalanceRepository();
    viewModel = MonthComparisonViewModel(transactions, monthlyBalances);
  });

  group('MonthComparisonViewModel', () {
    test('load fetches both months and exposes the snapshots', () async {
      transactions.entriesByMonth = {
        index(2026, 9): [entry('sep-1', 10)],
        index(2026, 10): [entry('oct-1', 20), entry('oct-2', 30)],
      };
      monthlyBalances.uncontrolledByMonth = {index(2026, 10): -20};

      await viewModel.load(DateTime(2026, 9, 15), DateTime(2026, 10, 3));

      expect(viewModel.beforeMonth, september);
      expect(viewModel.afterMonth, october);
      expect(viewModel.before!.month, september);
      expect(viewModel.before!.entries.map((e) => e.id), ['sep-1']);
      expect(viewModel.after!.entries.map((e) => e.id), ['oct-1', 'oct-2']);
      expect(viewModel.after!.uncontrolledTotal, -20);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('both months are requested in parallel', () async {
      final gate = Completer<void>();
      transactions.beforeLoad = (_) => gate.future;

      final loading = viewModel.load(september, october);
      await Future<void>.delayed(Duration.zero);

      expect(transactions.requestedMonths, hasLength(2));
      expect(viewModel.isLoading, isTrue);

      gate.complete();
      await loading;
    });

    test('the same month is not fetched', () async {
      await viewModel.load(september, DateTime(2026, 9, 20));

      expect(transactions.requestedMonths, isEmpty);
      expect(viewModel.hasSameMonth, isTrue);
      expect(viewModel.before, isNull);
      expect(viewModel.after, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('an error leaves no partial result', () async {
      transactions.loadError = Exception('boom');

      await viewModel.load(september, october);

      expect(
        viewModel.errorMessage,
        MonthComparisonViewModel.loadErrorMessage,
      );
      expect(viewModel.before, isNull);
      expect(viewModel.after, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('an uncontrolled total error also leaves no partial result',
        () async {
      monthlyBalances.uncontrolledError = Exception('boom');

      await viewModel.load(september, october);

      expect(
        viewModel.errorMessage,
        MonthComparisonViewModel.loadErrorMessage,
      );
      expect(viewModel.before, isNull);
      expect(viewModel.after, isNull);
    });

    test('a stale response is ignored', () async {
      transactions.entriesByMonth = {
        index(2026, 8): [entry('aug-1', 5)],
      };
      final gate = Completer<void>();
      var calls = 0;
      // Only the two requests of the first load are held back.
      transactions.beforeLoad = (_) {
        calls++;
        return calls <= 2 ? gate.future : Future<void>.value();
      };

      final first = viewModel.load(september, october);
      await Future<void>.delayed(Duration.zero);
      await viewModel.load(august, september);
      gate.complete();
      await first;

      expect(viewModel.beforeMonth, august);
      expect(viewModel.before!.month, august);
      expect(viewModel.before!.entries.map((e) => e.id), ['aug-1']);
      expect(viewModel.isLoading, isFalse);
    });

    test('a new load clears the previous result right away', () async {
      await viewModel.load(september, october);
      expect(viewModel.before, isNotNull);

      final loading = viewModel.load(august, september);

      expect(viewModel.before, isNull);
      expect(viewModel.after, isNull);
      expect(viewModel.isLoading, isTrue);

      await loading;
    });

    test('retry reloads the last months', () async {
      transactions.loadError = Exception('boom');
      await viewModel.load(september, october);
      transactions.loadError = null;

      await viewModel.retry();

      expect(viewModel.before, isNotNull);
      expect(viewModel.after, isNotNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('swap exchanges the months', () async {
      await viewModel.load(september, october);

      await viewModel.swap();

      expect(viewModel.beforeMonth, october);
      expect(viewModel.afterMonth, september);
      expect(viewModel.before!.month, october);
    });

    test('retry and swap do nothing before the first load', () async {
      await viewModel.retry();
      await viewModel.swap();

      expect(transactions.requestedMonths, isEmpty);
      expect(viewModel.isLoading, isFalse);
    });
  });
}
