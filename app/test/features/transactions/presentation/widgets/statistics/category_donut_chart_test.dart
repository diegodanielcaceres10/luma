import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/currency_format.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/presentation/view_models/transaction_totals.dart';
import 'package:luma/features/transactions/presentation/widgets/statistics/category_donut_chart.dart';

void main() {
  const breakdown = [
    CategoryTotal(
      category: TransactionCategory(
        id: 'a',
        name: 'Categoria 1',
        color: '#EC4899',
      ),
      amount: 8,
      percent: 100,
    ),
  ];

  Future<void> pump(WidgetTester tester, {double? size}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: size == null
                ? const StatisticsCategoryDonutChart(
                    breakdown: breakdown,
                    total: 8,
                    currency: 'USD',
                  )
                : StatisticsCategoryDonutChart(
                    breakdown: breakdown,
                    total: 8,
                    currency: 'USD',
                    size: size,
                  ),
          ),
        ),
      ),
    );
  }

  double fontSizeOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.fontSize!;

  testWidgets('is 128 px by default', (tester) async {
    await pump(tester);

    expect(
      tester.getSize(find.byType(StatisticsCategoryDonutChart)),
      const Size(128, 128),
    );
    expect(fontSizeOf(tester, 'Total gastos'), 11);
  });

  testWidgets('takes the requested size', (tester) async {
    await pump(tester, size: 240);

    expect(
      tester.getSize(find.byType(StatisticsCategoryDonutChart)),
      const Size(240, 240),
    );
  });

  testWidgets('scales the center text with the size', (tester) async {
    await pump(tester, size: 256);

    // Twice the default size, twice the default text.
    expect(fontSizeOf(tester, 'Total gastos'), closeTo(22, 0.01));
    expect(fontSizeOf(tester, formatCurrency(8, 'USD')), closeTo(28, 0.01));
  });

  testWidgets('does not overflow with a large total', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatisticsCategoryDonutChart(
              breakdown: breakdown,
              total: 1234567.89,
              currency: 'USD',
              size: 180,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
