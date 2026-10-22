import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/presentation/view_models/transaction_totals.dart';
import 'package:luma/features/transactions/presentation/widgets/statistics/category_donut_chart.dart';
import 'package:luma/features/transactions/presentation/widgets/statistics/category_legend_row.dart';
import 'package:luma/features/transactions/presentation/widgets/statistics/donut_with_legend.dart';

void main() {
  final breakdown = [
    const CategoryTotal(
      category: TransactionCategory(id: 'a', name: 'Categorizados'),
      amount: 8,
      percent: 89,
    ),
    const CategoryTotal(
      category: TransactionCategory(id: 'b', name: 'No categorizados'),
      amount: 1,
      percent: 11,
    ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required double width,
    String? label,
  }) {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: StatisticsDonutWithLegend(
                breakdown: breakdown,
                total: 9,
                currency: 'USD',
                label: label,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Rect legendBlock(WidgetTester tester) => tester.getRect(
        find.descendant(
          of: find.byType(StatisticsCategoryLegend),
          matching: find.byType(IntrinsicWidth),
        ),
      );

  group('with room for two columns', () {
    testWidgets('centers the chart in the left half', (tester) async {
      await pump(tester, width: 900);

      final chart = tester.getRect(find.byType(StatisticsCategoryDonutChart));

      expect(chart.center.dx, closeTo(900 * 0.25, 1));
    });

    testWidgets('centers the legend in the right half', (tester) async {
      await pump(tester, width: 900);

      final legend = legendBlock(tester);

      expect(legend.left, greaterThanOrEqualTo(450));
      expect(legend.right, lessThanOrEqualTo(900));
      expect(legend.center.dx, closeTo(900 * 0.75, 1));
    });

    testWidgets('keeps the percentages in a column next to the names',
        (tester) async {
      await pump(tester, width: 900);

      final first = tester.getRect(find.text('89%'));
      final second = tester.getRect(find.text('11%'));
      final longestName = tester.getRect(find.text('No categorizados'));

      expect(first.right, second.right);
      expect(second.left - longestName.right, lessThan(40));
    });

    testWidgets('does not overflow', (tester) async {
      await pump(tester, width: 900);

      expect(tester.takeException(), isNull);
    });
  });

  group('chart size', () {
    double chartSide(WidgetTester tester) =>
        tester.getSize(find.byType(StatisticsCategoryDonutChart)).width;

    testWidgets('grows with the width of its half', (tester) async {
      await pump(tester, width: 600);

      // 70 % of the 300 px half.
      expect(chartSide(tester), closeTo(210, 0.01));
    });

    testWidgets('is 154 px right where the two columns start', (tester) async {
      await pump(tester, width: 440);

      expect(chartSide(tester), closeTo(154, 0.01));
    });

    testWidgets('never gets smaller than the default size', (tester) async {
      await pump(tester, width: 440);

      expect(chartSide(tester), greaterThanOrEqualTo(128));
    });

    testWidgets('stops growing at 240 px', (tester) async {
      await pump(tester, width: 900);

      expect(chartSide(tester), 240);
    });

    testWidgets('makes the card taller as the chart grows', (tester) async {
      await pump(tester, width: 900);

      final block = tester.getSize(find.byType(StatisticsDonutWithLegend));
      expect(block.height, greaterThanOrEqualTo(240));
    });

    testWidgets('stays at the default size without room for two columns',
        (tester) async {
      await pump(tester, width: 300);

      expect(chartSide(tester), 128);
    });

    testWidgets('scales the text in the middle with the chart',
        (tester) async {
      await pump(tester, width: 900);

      final label = tester.widget<Text>(find.text('Total gastos'));
      expect(label.style!.fontSize, closeTo(11 * 240 / 128, 0.01));
    });
  });

  group('without room for two columns', () {
    testWidgets('puts the legend right after the chart', (tester) async {
      await pump(tester, width: 300);

      final chart = tester.getRect(find.byType(StatisticsCategoryDonutChart));
      final legend = legendBlock(tester);

      expect(chart.left, 0);
      expect(legend.left, chart.right + 18);
    });

    testWidgets('does not overflow', (tester) async {
      await pump(tester, width: 300);

      expect(tester.takeException(), isNull);
      expect(find.text('89%'), findsOneWidget);
    });

    testWidgets('switches to two columns from 440 px', (tester) async {
      await pump(tester, width: 439);
      final narrowChart =
          tester.getRect(find.byType(StatisticsCategoryDonutChart));
      expect(narrowChart.left, 0);

      await pump(tester, width: 440);
      final wideChart =
          tester.getRect(find.byType(StatisticsCategoryDonutChart));
      expect(wideChart.left, greaterThan(0));
    });
  });

  group('chart label', () {
    testWidgets('defaults to "Total gastos"', (tester) async {
      await pump(tester, width: 900);

      expect(find.text('Total gastos'), findsOneWidget);
    });

    testWidgets('can be replaced', (tester) async {
      await pump(tester, width: 900, label: 'Gasto real');

      expect(find.text('Gasto real'), findsOneWidget);
      expect(find.text('Total gastos'), findsNothing);
    });
  });
}
