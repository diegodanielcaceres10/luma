import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/currency_format.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/presentation/view_models/transaction_totals.dart';
import 'package:luma/features/transactions/presentation/widgets/statistics/category_legend_row.dart';

Widget host({required double width, required String name}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: StatisticsCategoryLegendRow(
            category: CategoryTotal(
              category: TransactionCategory(name: name),
              amount: 1158.53,
              percent: 95,
            ),
            currency: 'EUR',
          ),
        ),
      ),
    ),
  );
}

void main() {
  final amountText = formatCurrency(1158.53, 'EUR');

  group('StatisticsCategoryLegendRow', () {
    testWidgets('shows the amount below the name', (tester) async {
      await tester.pumpWidget(host(width: 200, name: 'Categorizado'));

      final name = tester.getRect(find.text('Categorizado'));
      final amount = tester.getRect(find.text(amountText));

      expect(amount.top, greaterThanOrEqualTo(name.bottom));
      expect(amount.left, name.left);
    });

    testWidgets('shows the percentage', (tester) async {
      await tester.pumpWidget(host(width: 200, name: 'Categorizado'));

      expect(find.text('95%'), findsOneWidget);
    });

    testWidgets('does not overflow on a narrow width with a long name',
        (tester) async {
      await tester.pumpWidget(host(width: 150, name: 'No categorizados'));

      expect(tester.takeException(), isNull);
      expect(find.text(amountText), findsOneWidget);
    });
  });
}
