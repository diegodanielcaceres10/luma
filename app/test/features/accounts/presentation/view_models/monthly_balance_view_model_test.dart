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

  group('saveOpeningBalance for another month', () {
    DateTime previousMonth() =>
        DateTime(viewModel.currentYear, viewModel.currentMonth - 1);

    Future<bool> savePast({double? uncontrolled}) {
      final past = previousMonth();
      return viewModel.saveOpeningBalance(
        userId: 'user-1',
        accountId: 'a',
        openingBalance: 250,
        month: past.month,
        year: past.year,
        uncontrolledExpensesTotal: uncontrolled,
      );
    }

    test('saves the given month with its uncontrolled total', () async {
      final past = previousMonth();

      final saved = await savePast(uncontrolled: -40);

      expect(saved, isTrue);
      expect(repository.saved, [
        (accountId: 'a', month: past.month, year: past.year, amount: 250.0),
      ]);
      expect(repository.uncontrolledTotals, [-40.0]);
    });

    test('keeps the account pending for the current month', () async {
      await savePast();

      expect(viewModel.isAccountPending('a'), isTrue);
    });

    test('marks the account as done when the month is the current one',
        () async {
      await viewModel.saveOpeningBalance(
        userId: 'user-1',
        accountId: 'a',
        openingBalance: 250,
        month: viewModel.currentMonth,
        year: viewModel.currentYear,
      );

      expect(viewModel.isAccountPending('a'), isFalse);
    });

    test('remembers the saved month for the account', () async {
      final past = previousMonth();

      await savePast();

      expect(
        viewModel.openingMonthsByAccount['a'],
        contains(past.year * 12 + past.month),
      );
    });

    test('reports an error and remembers nothing when it fails', () async {
      repository.saveError = Exception('boom');

      final saved = await savePast();

      expect(saved, isFalse);
      expect(viewModel.errorMessage, 'No se pudo guardar el saldo inicial.');
      expect(viewModel.openingMonthsByAccount['a'], isNull);
    });
  });

  group('loadOpeningMonths', () {
    test('loads the months with an opening balance of each account',
        () async {
      repository.openingMonths = {
        'a': {2026 * 12 + 6, 2026 * 12 + 10},
      };

      await viewModel.loadOpeningMonths();

      expect(viewModel.openingMonthsLoaded, isTrue);
      expect(viewModel.openingMonthsByAccount['a'],
          {2026 * 12 + 6, 2026 * 12 + 10});
    });

    test('stays unloaded without throwing when the repository fails',
        () async {
      repository.loadError = Exception('network down');

      await viewModel.loadOpeningMonths();

      expect(viewModel.openingMonthsLoaded, isFalse);
      expect(viewModel.openingMonthsByAccount, isEmpty);
    });

    test('notifies listeners once loaded', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.loadOpeningMonths();

      expect(notifications, greaterThan(0));
    });
  });

  group('accountIdsWithOpeningBalance', () {
    test('returns the accounts with a record in the given month', () async {
      repository.existingIds = {'a'};

      final ids = await viewModel.accountIdsWithOpeningBalance(
        month: 8,
        year: 2026,
      );

      expect(ids, {'a'});
      expect(repository.requestedMonths, [(month: 8, year: 2026)]);
    });

    test('does not change which accounts are pending this month', () async {
      repository.existingIds = {'a'};

      await viewModel.accountIdsWithOpeningBalance(month: 8, year: 2026);

      expect(viewModel.isAccountPending('a'), isTrue);
    });

    test('returns null and reports an error when it cannot be checked',
        () async {
      repository.loadError = Exception('boom');

      final ids = await viewModel.accountIdsWithOpeningBalance(
        month: 8,
        year: 2026,
      );

      expect(ids, isNull);
      expect(
        viewModel.errorMessage,
        'No se pudo comprobar el saldo inicial del mes.',
      );
    });
  });

  group('openingBalancesOfMonth', () {
    test('returns the opening balance of each account in the month',
        () async {
      repository.openingBalances = {'a': 120.5, 'b': -30};

      final balances = await viewModel.openingBalancesOfMonth(
        month: 9,
        year: 2026,
      );

      expect(balances, {'a': 120.5, 'b': -30.0});
      expect(repository.requestedMonths, [(month: 9, year: 2026)]);
      expect(viewModel.errorMessage, isNull);
    });

    test('returns an empty map when no account has a record', () async {
      final balances = await viewModel.openingBalancesOfMonth(
        month: 9,
        year: 2026,
      );

      expect(balances, isEmpty);
    });

    test('returns null and reports an error when it cannot be read',
        () async {
      repository.loadError = Exception('boom');

      final balances = await viewModel.openingBalancesOfMonth(
        month: 9,
        year: 2026,
      );

      expect(balances, isNull);
      expect(
        viewModel.errorMessage,
        'No se pudo leer el saldo inicial del mes.',
      );
    });

    test('does not change which accounts are pending this month', () async {
      repository.openingBalances = {'a': 120.5};

      await viewModel.openingBalancesOfMonth(month: 9, year: 2026);

      expect(viewModel.isAccountPending('a'), isTrue);
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
