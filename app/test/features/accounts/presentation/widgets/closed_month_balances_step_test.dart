import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/currency_format.dart';
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
  late TextEditingController closing;

  setUp(() {
    opening = TextEditingController();
    closing = TextEditingController();
  });

  tearDown(() {
    opening.dispose();
    closing.dispose();
  });

  Widget host({
    required List<Account> accounts,
    String? selectedAccountId,
    ValueChanged<String>? onSelectAccount,
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
            closingController: closing,
            currency: 'USD',
            monthLabel: 'agosto 2026',
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
    expect(find.byType(ChoiceChip), findsNothing);
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

    expect(find.byType(ChoiceChip), findsNWidgets(2));
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Cuenta 1'))
          .selected,
      isTrue,
    );

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

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Cuenta Extra'),
    );

    expect(chip.onSelected, isNull);
  });

  testWidgets('labels both balances with the month', (tester) async {
    await tester.pumpWidget(host(accounts: [account('a', 'Cuenta 1')]));

    expect(find.text('Saldo inicial de agosto 2026'), findsOneWidget);
    expect(find.text('Saldo final de agosto 2026'), findsOneWidget);
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
