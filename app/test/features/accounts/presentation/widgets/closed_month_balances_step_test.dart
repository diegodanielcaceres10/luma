import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/currency_format.dart';
import 'package:luma/core/widgets/filter_chip_row.dart';
import 'package:luma/features/accounts/data/models/account.dart';
import 'package:luma/features/accounts/presentation/widgets/closed_month_balances_step.dart';

Account account(String id, String name) => Account(
      id: id,
      name: name,
      balance: 0,
      isActive: true,
      balanceUpdatedAt: DateTime(2026, 10, 1),
    );

void main() {
  late TextEditingController opening;

  setUp(() {
    opening = TextEditingController();
  });

  tearDown(() {
    opening.dispose();
  });

  Widget host({
    required List<Account> accounts,
    String? selectedAccountId,
    ValueChanged<String>? onSelectAccount,
    double? closingBalance,
    ClosingBalanceStatus closingStatus = ClosingBalanceStatus.available,
    VoidCallback? onRetryClosing,
    double? difference,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ClosedMonthBalancesStep(
            accounts: accounts,
            selectedAccountId: selectedAccountId,
            onSelectAccount: onSelectAccount,
            openingController: opening,
            closingBalance: closingBalance,
            closingStatus: closingStatus,
            onRetryClosing: onRetryClosing,
            currency: 'USD',
            monthLabel: 'agosto 2026',
            nextMonthLabel: 'septiembre 2026',
            difference: difference,
          ),
        ),
      ),
    );
  }

  testWidgets('shows only the name when there is a single account',
      (tester) async {
    await tester.pumpWidget(host(accounts: [account('a', 'Cuenta 1')]));

    expect(find.text('Cuenta 1'), findsOneWidget);
    expect(find.byType(FilterChipRow<String?>), findsNothing);
  });

  testWidgets('lets the user pick among several accounts', (tester) async {
    String? picked;
    await tester.pumpWidget(
      host(
        accounts: [account('a', 'Cuenta 1'), account('b', 'Cuenta Extra')],
        selectedAccountId: 'a',
        onSelectAccount: (id) => picked = id,
      ),
    );

    final row = tester.widget<FilterChipRow<String?>>(
      find.byType(FilterChipRow<String?>),
    );
    expect(row.options.map((o) => o.label), ['Cuenta 1', 'Cuenta Extra']);
    expect(row.selectedValue, 'a');

    await tester.tap(find.text('Cuenta Extra'));

    expect(picked, 'b');
  });

  testWidgets('does not react to taps while selection is disabled',
      (tester) async {
    await tester.pumpWidget(
      host(
        accounts: [account('a', 'Cuenta 1'), account('b', 'Cuenta Extra')],
      ),
    );

    final lock = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey('accountPickerLock')),
    );
    expect(lock.ignoring, isTrue);
  });

  testWidgets('keeps the picker active while selection is enabled',
      (tester) async {
    await tester.pumpWidget(
      host(
        accounts: [account('a', 'Cuenta 1'), account('b', 'Cuenta Extra')],
        onSelectAccount: (_) {},
      ),
    );

    final lock = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey('accountPickerLock')),
    );
    expect(lock.ignoring, isFalse);
  });

  testWidgets('labels both balances with the month', (tester) async {
    await tester.pumpWidget(host(accounts: [account('a', 'Cuenta 1')]));

    expect(find.text('Saldo inicial de agosto 2026'), findsOneWidget);
    expect(find.text('Saldo final de agosto 2026'), findsOneWidget);
  });

  testWidgets('only the opening balance is an input', (tester) async {
    await tester.pumpWidget(
      host(accounts: [account('a', 'Cuenta 1')], closingBalance: 150),
    );

    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('shows the next month opening balance as the closing one',
      (tester) async {
    await tester.pumpWidget(
      host(accounts: [account('a', 'Cuenta 1')], closingBalance: -30),
    );

    expect(find.text('-30,00'), findsOneWidget);
    // One symbol prefixes the typed opening balance, the other the closing.
    expect(find.text(currencySymbol('USD')), findsNWidgets(2));
    expect(
      find.text('Es el saldo inicial de septiembre 2026.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a progress indicator while the balance loads',
      (tester) async {
    await tester.pumpWidget(
      host(
        accounts: [account('a', 'Cuenta 1')],
        closingStatus: ClosingBalanceStatus.loading,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('saldo inicial de septiembre'), findsNothing);
  });

  testWidgets('explains why it cannot continue when the next month has no '
      'opening balance', (tester) async {
    await tester.pumpWidget(
      host(
        accounts: [account('a', 'Cuenta 1')],
        closingStatus: ClosingBalanceStatus.missing,
      ),
    );

    expect(
      find.text(
        'Esta cuenta no tiene saldo inicial en septiembre 2026. Sin ese dato '
        'no se puede justificar agosto 2026.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('asks to pick an account before showing the closing balance',
      (tester) async {
    await tester.pumpWidget(
      host(
        accounts: [account('a', 'Cuenta 1'), account('b', 'Cuenta Extra')],
        closingStatus: ClosingBalanceStatus.noAccount,
      ),
    );

    expect(
      find.text(
        'Elegí una cuenta para ver el saldo inicial de septiembre 2026.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('no tiene saldo inicial'), findsNothing);
  });

  testWidgets('offers a retry when the balance could not be read',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      host(
        accounts: [account('a', 'Cuenta 1')],
        closingStatus: ClosingBalanceStatus.failed,
        onRetryClosing: () => retries++,
      ),
    );

    expect(
      find.text('No pudimos leer el saldo inicial de septiembre 2026.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar'));

    expect(retries, 1);
  });

  testWidgets('shows the difference only once it is known', (tester) async {
    await tester.pumpWidget(host(accounts: [account('a', 'Cuenta 1')]));
    expect(find.textContaining('Diferencia del mes'), findsNothing);

    await tester.pumpWidget(
      host(accounts: [account('a', 'Cuenta 1')], difference: 60),
    );

    expect(
      find.text('Diferencia del mes: ${formatCurrency(60, 'USD')}'),
      findsOneWidget,
    );
  });
}
