import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/account.dart';
import 'package:luma/features/accounts/data/models/monthly_opening_balance.dart';
import 'package:luma/features/accounts/presentation/view_models/account_view_model.dart';
import 'package:luma/features/auth/presentation/view_models/preferences_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/fakes.dart';

Account account(
  String id, {
  String? name,
  double balance = 0,
  bool isActive = true,
}) =>
    Account(
      id: id,
      name: name ?? id,
      balance: balance,
      isActive: isActive,
      balanceUpdatedAt: DateTime(2026, 10, 1),
    );

void main() {
  late FakeAccountRepository repository;
  late PreferencesViewModel preferences;
  late AccountViewModel viewModel;

  setUp(() {
    repository = FakeAccountRepository();
    preferences = PreferencesViewModel(FakePreferencesRepository());
    viewModel = AccountViewModel(repository, preferences);
  });

  tearDown(() {
    viewModel.dispose();
    preferences.dispose();
  });

  group('loadAccounts', () {
    test('fills the list sorted without regard to case', () async {
      repository.accounts = [
        account('1', name: 'banco'),
        account('2', name: 'Zeta'),
        account('3', name: 'Alfa'),
      ];

      await viewModel.loadAccounts();

      expect(viewModel.accounts.map((a) => a.name), ['Alfa', 'banco', 'Zeta']);
      expect(viewModel.hasLoaded, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('notifies when loading starts and when it ends', () async {
      final states = <bool>[];
      viewModel.addListener(() => states.add(viewModel.isLoading));

      await viewModel.loadAccounts();

      expect(states, [true, false]);
    });

    test('reports an error without throwing when the repository fails',
        () async {
      repository.loadError = Exception('network down');

      await viewModel.loadAccounts();

      expect(viewModel.errorMessage, 'No se pudieron cargar las cuentas.');
      expect(viewModel.accounts, isEmpty);
      expect(viewModel.hasLoaded, isFalse);
      expect(viewModel.isLoading, isFalse);
    });
  });

  group('active accounts and total', () {
    setUp(() async {
      repository.accounts = [
        account('a', balance: 100.5),
        account('b', balance: 20),
        account('c', balance: 1000, isActive: false),
      ];
      await viewModel.loadAccounts();
    });

    test('activeAccounts leaves out inactive accounts', () {
      expect(viewModel.activeAccounts.map((a) => a.id), ['a', 'b']);
      expect(viewModel.accounts, hasLength(3));
    });

    test('totalBalance adds up only the active accounts', () {
      expect(viewModel.totalBalance, 120.5);
    });

    test('totalBalance is zero without accounts', () async {
      repository.accounts = [];
      await viewModel.loadAccounts();

      expect(viewModel.totalBalance, 0);
    });
  });

  group('submitting changes', () {
    test('toggleActive calls the repository and reloads the list', () async {
      repository.accounts = [account('a', isActive: false)];

      final toggled = await viewModel.toggleActive('a', false);

      expect(toggled, isTrue);
      expect(repository.setActiveCalls, [(id: 'a', isActive: false)]);
      expect(repository.getAccountsCalls, 1);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.submitError, isNull);
    });

    test('toggleActive reports a generic error when the repository fails',
        () async {
      repository.writeError = Exception('boom');

      final toggled = await viewModel.toggleActive('a', false);

      expect(toggled, isFalse);
      expect(viewModel.submitError, AccountSubmitError.generic);
      expect(viewModel.errorMessage, 'No se pudo guardar la cuenta.');
      expect(viewModel.isSubmitting, isFalse);
    });

    test('createAccount flags a duplicate name on a unique violation',
        () async {
      repository.writeError = const PostgrestException(
        message: 'duplicate key',
        code: '23505',
      );

      final created = await viewModel.createAccount(
        userId: 'user-1',
        name: 'Banco',
        balance: 10,
      );

      expect(created, isFalse);
      expect(viewModel.submitError, AccountSubmitError.duplicate);
      expect(viewModel.errorMessage, 'Ya existe una cuenta con ese nombre.');
    });

    test('createAccount flags a generic error for other database errors',
        () async {
      repository.writeError = const PostgrestException(
        message: 'boom',
        code: '42000',
      );

      final created = await viewModel.createAccount(
        userId: 'user-1',
        name: 'Banco',
        balance: 10,
      );

      expect(created, isFalse);
      expect(viewModel.submitError, AccountSubmitError.generic);
    });
  });

  group('uncontrolled adjustment', () {
    Future<bool> adjust() => viewModel.applyUncontrolledAdjustment(
          userId: 'user-1',
          accountId: 'a',
          amount: -15,
          month: 10,
          year: 2026,
        );

    test('loads the uncontrolled total after a successful adjustment',
        () async {
      repository.uncontrolledTotal = -15;

      final applied = await adjust();

      expect(applied, isTrue);
      expect(viewModel.uncontrolledTotalOf('a'), -15);
    });

    test('reports its own error message when the adjustment fails',
        () async {
      repository.writeError = Exception('boom');

      final applied = await adjust();

      expect(applied, isFalse);
      expect(
        viewModel.errorMessage,
        'No se pudo guardar el ajuste no declarado.',
      );
      expect(viewModel.uncontrolledTotalOf('a'), 0);
    });

    test('keeps the previous total when loading it fails', () async {
      repository.uncontrolledTotal = 40;
      await viewModel.loadUncontrolledTotal('a');

      repository.secondaryError = Exception('boom');
      await viewModel.loadUncontrolledTotal('a');

      expect(viewModel.uncontrolledTotalOf('a'), 40);
    });

    test('uncontrolledTotalOf is zero when nothing was loaded', () {
      expect(viewModel.uncontrolledTotalOf('unknown'), 0);
    });
  });

  group('opening history and month variation', () {
    test('openingHistoryOf is empty until loaded', () async {
      expect(viewModel.openingHistoryOf('a'), isEmpty);

      final now = DateTime.now();
      repository.openingBalances = [
        MonthlyOpeningBalance(
          month: now.month,
          year: now.year,
          openingBalance: 100,
        ),
      ];
      await viewModel.loadOpeningHistory('a');

      expect(viewModel.openingHistoryOf('a'), hasLength(1));
    });

    test('monthVariationOf compares the live balance with the opening balance',
        () async {
      final now = DateTime.now();
      repository.accounts = [account('a', balance: 150)];
      repository.openingBalances = [
        MonthlyOpeningBalance(
          month: now.month,
          year: now.year,
          openingBalance: 100,
        ),
      ];
      await viewModel.loadAccounts();
      await viewModel.loadOpeningHistory('a');

      expect(viewModel.monthVariationOf('a'), 50);
    });

    test('monthVariationOf is null without an opening balance', () async {
      repository.accounts = [account('a', balance: 150)];
      await viewModel.loadAccounts();

      expect(viewModel.monthVariationOf('a'), isNull);
    });

    test('monthVariationOf is null for an unknown account', () {
      expect(viewModel.monthVariationOf('unknown'), isNull);
    });
  });

  group('preferences', () {
    test('primaryCurrency follows the preferences', () async {
      expect(viewModel.primaryCurrency, 'USD');

      await preferences.setCurrencyCode('EUR');

      expect(viewModel.primaryCurrency, 'EUR');
    });

    test('forwards preference changes to its own listeners', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await preferences.setCurrencyCode('EUR');

      expect(notifications, greaterThan(0));
    });

    test('stops listening to the preferences once disposed', () async {
      final other = AccountViewModel(repository, preferences);
      other.dispose();

      await expectLater(preferences.setCurrencyCode('EUR'), completes);
    });
  });
}
