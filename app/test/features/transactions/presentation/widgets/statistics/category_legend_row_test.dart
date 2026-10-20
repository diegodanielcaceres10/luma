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

    testWidgets('shows the percentage larger than the amount', (tester) async {
      await tester.pumpWidget(host(width: 200, name: 'Categorizado'));

      final percent = tester.widget<Text>(find.text('95%'));
      final amount = tester.widget<Text>(find.text(amountText));
      expect(percent.style?.fontSize, 15);
      expect(percent.style!.fontSize!, greaterThan(amount.style!.fontSize!));
    });

    testWidgets('fits a 100% without overflowing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 150,
                child: StatisticsCategoryLegendRow(
                  category: CategoryTotal(
                    category: TransactionCategory(name: 'Categoria 1'),
                    amount: 8,
                    percent: 100,
                  ),
                  currency: 'USD',
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('does not overflow on a narrow width with a long name',
        (tester) async {
      await tester.pumpWidget(host(width: 150, name: 'No categorizados'));

      expect(tester.takeException(), isNull);
      expect(find.text(amountText), findsOneWidget);
    });
  });

  group('StatisticsCategoryLegend', () {
    CategoryTotal total(String name, double amount, double percent) {
      return CategoryTotal(
        category: TransactionCategory(name: name),
        amount: amount,
        percent: percent,
      );
    }

    Widget legendHost({required double width}) {
      return MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              // Stands for the donut chart next to the legend.
              const SizedBox(width: 100),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: StatisticsCategoryLegend(
                      breakdown: [
                        total('Alquiler', 800, 80),
                        total('Supermercado y más', 200, 20),
                      ],
                      currency: 'EUR',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('keeps the percentage next to the longest line',
        (tester) async {
      await tester.pumpWidget(legendHost(width: 600));

      final longestName = tester.getRect(find.text('Supermercado y más'));
      final percent = tester.getRect(find.text('20%'));

      expect(percent.left - longestName.right, lessThan(40));
      // The legend hugs its content: the percentage ends well short of the
      // 600 px it could have taken. Relative, because tests render text with a
      // much wider font than the app does.
      expect(percent.right, lessThan(100 + 600 * 0.8));
    });

    testWidgets('aligns the percentages of all rows in a column',
        (tester) async {
      await tester.pumpWidget(legendHost(width: 600));

      final first = tester.getRect(find.text('80%'));
      final second = tester.getRect(find.text('20%'));

      expect(first.right, second.right);
    });

    testWidgets('does not overflow on a narrow width', (tester) async {
      await tester.pumpWidget(legendHost(width: 120));

      expect(tester.takeException(), isNull);
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('shows one row per category', (tester) async {
      await tester.pumpWidget(legendHost(width: 600));

      expect(find.byType(StatisticsCategoryLegendRow), findsNWidgets(2));
    });
  });
}
