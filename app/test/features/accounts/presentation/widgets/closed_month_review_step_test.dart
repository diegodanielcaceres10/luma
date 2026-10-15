import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/currency_format.dart';
import 'package:luma/features/accounts/presentation/widgets/closed_month_review_step.dart';

void main() {
  Widget host({
    double? opening = 100,
    double? closing = 160,
    double? difference = 60,
    double? remainder = 0,
    double movementsTotal = 60,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ClosedMonthReviewStep(
            movements: const [],
            openingBalance: opening,
            closingBalance: closing,
            difference: difference,
            movementsTotal: movementsTotal,
            remainder: remainder,
            currency: 'USD',
            monthLabel: 'agosto 2026',
          ),
        ),
      ),
    );
  }

  testWidgets('summarizes the month when everything is justified',
      (tester) async {
    await tester.pumpWidget(host());

    expect(find.text('Saldo inicial'), findsOneWidget);
    expect(find.text(formatCurrency(160, 'USD')), findsOneWidget);
    expect(find.text('Todo justificado'), findsOneWidget);
  });

  testWidgets('says what stays uncontrolled when the justification is partial',
      (tester) async {
    await tester.pumpWidget(host(remainder: 20, movementsTotal: 40));

    expect(find.text('Justificación parcial'), findsOneWidget);
    expect(
      find.text(
        'Van a quedar ${formatCurrency(20, 'USD')} como ingreso sin declarar '
        'de agosto 2026.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows no summary while a balance is missing', (tester) async {
    await tester.pumpWidget(host(closing: null, difference: null));

    expect(find.text('Saldo inicial'), findsNothing);
  });

  testWidgets('shows no list of movements when none were loaded',
      (tester) async {
    await tester.pumpWidget(host());

    expect(find.text('Movimientos cargados'), findsNothing);
  });
}
