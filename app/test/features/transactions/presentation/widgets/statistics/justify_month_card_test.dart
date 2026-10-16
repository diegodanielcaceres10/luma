import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/transactions/presentation/widgets/statistics/justify_month_card.dart';

Widget host({
  required List<String> accountNames,
  required VoidCallback onPressed,
}) {
  return MaterialApp(
    home: Scaffold(
      body: StatisticsJustifyMonthCard(
        monthLabel: 'agosto 2026',
        accountNames: accountNames,
        onPressed: onPressed,
      ),
    ),
  );
}

void main() {
  group('StatisticsJustifyMonthCard', () {
    testWidgets('names the month and lists the accounts', (tester) async {
      await tester.pumpWidget(
        host(accountNames: ['Cuenta 1', 'Cuenta Extra'], onPressed: () {}),
      );

      expect(find.text('Sin cargar en agosto 2026'), findsOneWidget);
      expect(find.text('Cuenta 1, Cuenta Extra'), findsOneWidget);
    });

    testWidgets('calls onPressed when the button is tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(accountNames: ['Cuenta 1'], onPressed: () => taps++),
      );

      await tester.tap(find.text('Justificar'));

      expect(taps, 1);
    });
  });
}
