import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/account.dart';
import 'package:luma/features/accounts/presentation/view_models/monthly_balance_view_model.dart';

import '../../../../helpers/fakes.dart';

Account account(String id) => Account(
      id: id,
      name: id,
      balance: 0,
      isActive: true,
      balanceUpdatedAt: DateTime(2026, 10, 1),
    );

void main() {
  late FakeMonthlyBalanceRepository repository;
  late MonthlyBalanceViewModel viewModel;

  setUp(() {
    repository = FakeMonthlyBalanceRepository();
    viewModel = MonthlyBalanceViewModel(repository);
  });

  tearDown(() => viewModel.dispose());

  group('checkCurrentMonth', () {
    test('is unchecked and treats every account as pending at first', () {
      expect(viewModel.checked, isFalse);
      expect(viewModel.isAccountPending('a'), isTrue);
    });

    test('asks for the current month and marks accounts with a balance',
        () async {
      repository.existingIds = {'a'};

      await viewModel.checkCurrentMonth();

      expect(viewModel.checked, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(repository.requestedMonths, [
        (month: viewModel.currentMonth, year: viewModel.currentYear),
      ]);
      expect(viewModel.isAccountPending('a'), isFalse);
      expect(viewModel.isAccountPending('b'), isTrue);
    });

    test('notifies when loading starts and when it ends', () async {
      final states = <bool>[];
      viewModel.addListener(() => states.add(viewModel.isLoading));

      await viewModel.checkCurrentMonth();

      expect(states, [true, false]);
    });

    test('stays unchecked without throwing when the repository fails',
        () async {
      repository.loadError = Exception('network down');

      await viewModel.checkCurrentMonth();

      expect(viewModel.checked, isFalse);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('pendingAccounts keeps only accounts without a balance', () async {
      repository.existingIds = {'a'};
      await viewModel.checkCurrentMonth();

      final pending = viewModel.pendingAccounts([account('a'), account('b')]);

      expect(pending.map((a) => a.id), ['b']);
    });
  });

  group('saveOpeningBalance', () {
    Future<bool> save() => viewModel.saveOpeningBalance(
          userId: 'user-1',
          accountId: 'a',
          openingBalance: 250,
        );

    test('saves the balance and stops treating the account as pending',
        () async {
      final saved = await save();

      expect(saved, isTrue);
      expect(repository.saved, [
        (
          accountId: 'a',
          month: viewModel.currentMonth,
          year: viewModel.currentYear,
          amount: 250.0,
        ),
      ]);
      expect(viewModel.isAccountPending('a'), isFalse);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('reports an error and keeps the account pending when it fails',
        () async {
      repository.saveError = Exception('boom');

      final saved = await save();

      expect(saved, isFalse);
      expect(viewModel.errorMessage, 'No se pudo guardar el saldo inicial.');
      expect(viewModel.isAccountPending('a'), isTrue);
      expect(viewModel.isSubmitting, isFalse);
    });
  });

  group('ensureOpeningBalance', () {
    Future<bool> ensure() => viewModel.ensureOpeningBalance(
          userId: 'user-1',
          accountId: 'a',
          month: 9,
          year: 2026,
          openingBalance: 80,
        );

    test('creates the record of the past month when it is missing',
        () async {
      final ensured = await ensure();

      expect(ensured, isTrue);
      expect(repository.requestedMonths, [(month: 9, year: 2026)]);
      expect(repository.saved, [
        (accountId: 'a', month: 9, year: 2026, amount: 80.0),
      ]);
    });

    test('does not save again when the record already exists', () async {
      repository.existingIds = {'a'};

      final ensured = await ensure();

      expect(ensured, isTrue);
      expect(repository.saved, isEmpty);
    });

    test('reports an error and returns false when it cannot be checked',
        () async {
      repository.loadError = Exception('boom');

      final ensured = await ensure();

      expect(ensured, isFalse);
      expect(
        viewModel.errorMessage,
        'No se pudo preparar el ciclo anterior.',
      );
      expect(repository.saved, isEmpty);
    });
  });
}
