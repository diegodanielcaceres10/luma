import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/account.dart';
import 'package:luma/features/home/presentation/widgets/dashboard/balance_accounts_expander.dart';

void main() {
  Account account(String id, String name) => Account(
        id: id,
        name: name,
        balance: 100,
        isActive: true,
        balanceUpdatedAt: DateTime(2026, 10, 1),
      );

  final accounts = [account('a1', 'Cuenta 1'), account('a2', 'Cuenta Extra')];

  final opened = <String>[];
  final completed = <String>[];

  setUp(() {
    opened.clear();
    completed.clear();
  });

  Future<void> pumpExpanded(
    WidgetTester tester, {
    Set<String> pending = const {},
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BalanceAccountsExpander(
              accounts: accounts,
              currency: 'USD',
              onOpenAccount: opened.add,
              pendingAccountIds: pending,
              onCompletePendingBalance: completed.add,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ver cuentas'));
    await tester.pumpAndSettle();
  }

  testWidgets('has no settings button next to the title', (tester) async {
    await pumpExpanded(tester);

    expect(find.text('Saldo por cuenta'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });

  testWidgets('shows a chevron on every account', (tester) async {
    await pumpExpanded(tester);

    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
  });

  testWidgets('opens the account that is tapped', (tester) async {
    await pumpExpanded(tester);

    await tester.tap(find.text('Cuenta Extra'));
    await tester.pump();

    expect(opened, ['a2']);
    expect(completed, isEmpty);
  });

  testWidgets('the chevron opens the account too', (tester) async {
    await pumpExpanded(tester);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
    await tester.pump();

    expect(opened, ['a1']);
  });

  group('with a missing opening balance', () {
    const warning = 'Falta cargar el saldo inicial';

    testWidgets('the warning completes the balance and nothing else',
        (tester) async {
      await pumpExpanded(tester, pending: {'a1'});

      await tester.tap(find.text(warning));
      await tester.pump();

      expect(completed, ['a1']);
      expect(opened, isEmpty);
    });

    testWidgets('the rest of the row still opens the account',
        (tester) async {
      await pumpExpanded(tester, pending: {'a1'});

      await tester.tap(find.text('Cuenta 1'));
      await tester.pump();

      expect(opened, ['a1']);
      expect(completed, isEmpty);
    });

    testWidgets('keeps one chevron for the row and one for the warning',
        (tester) async {
      await pumpExpanded(tester, pending: {'a1'});

      // Two accounts plus the warning's own chevron.
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));
    });
  });
}
