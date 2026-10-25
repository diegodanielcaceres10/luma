import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/currency_format.dart';
import 'package:luma/features/comparison/presentation/view_models/month_comparison.dart';
import 'package:luma/features/comparison/presentation/widgets/comparison_row_tile.dart';

Widget host(ComparisonRow row, {double width = 360}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: ComparisonRowTile(row: row, currency: 'EUR'),
        ),
      ),
    ),
  );
}

void main() {
  group('ComparisonRowTile', () {
    testWidgets('shows the label, both amounts, the percent and the difference',
        (tester) async {
      await tester.pumpWidget(host(const ComparisonRow(
        id: 'c1',
        label: 'Comida',
        before: 82000,
        after: 95000,
        difference: 13000,
        percentChange: 15.85,
        tone: ComparisonTone.unfavorable,
      )));

      expect(find.text('Comida'), findsOneWidget);
      expect(find.text(formatCurrency(82000, 'EUR')), findsOneWidget);
      expect(find.text(formatCurrency(95000, 'EUR')), findsOneWidget);
      expect(find.text('+16%'), findsOneWidget);
      expect(find.text('+${formatCurrency(13000, 'EUR')}'), findsOneWidget);
    });

    testWidgets('shows a negative change without a plus sign',
        (tester) async {
      await tester.pumpWidget(host(const ComparisonRow(
        id: 'c2',
        label: 'Transporte',
        before: 40000,
        after: 31000,
        difference: -9000,
        percentChange: -22.5,
        tone: ComparisonTone.favorable,
      )));

      expect(find.text('-23%'), findsOneWidget);
      expect(find.text(formatCurrency(-9000, 'EUR')), findsOneWidget);
    });

    testWidgets('a tiny negative change reads 0% and not -0%',
        (tester) async {
      await tester.pumpWidget(host(const ComparisonRow(
        id: 'c3',
        label: 'Hogar',
        before: 1000,
        after: 996,
        difference: -4,
        percentChange: -0.4,
      )));

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('-0%'), findsNothing);
    });

    testWidgets('shows Nuevo when the row is new', (tester) async {
      await tester.pumpWidget(host(const ComparisonRow(
        id: 'c4',
        label: 'Hogar',
        before: 0,
        after: 60000,
        difference: 60000,
        isNew: true,
        tone: ComparisonTone.unfavorable,
      )));

      expect(find.text('Nuevo'), findsOneWidget);
    });

    testWidgets('shows an em dash and no percent when a month has no data',
        (tester) async {
      await tester.pumpWidget(host(const ComparisonRow(
        id: 's2',
        label: 'Agua',
        before: 50000,
        after: null,
      )));

      expect(find.text('—'), findsWidgets);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('shows the budget line only when there is a budget',
        (tester) async {
      await tester.pumpWidget(host(const ComparisonRow(
        id: 'c1',
        label: 'Comida',
        before: 80000,
        after: 85000,
        difference: 5000,
        percentChange: 6.25,
        budget: 90000,
      )));

      expect(
        find.text('Presupuesto ${formatCurrency(90000, 'EUR')} / mes'),
        findsOneWidget,
      );

      await tester.pumpWidget(host(const ComparisonRow(
        id: 'c2',
        label: 'Transporte',
        before: 80000,
        after: 85000,
        difference: 5000,
        percentChange: 6.25,
      )));

      expect(find.textContaining('Presupuesto'), findsNothing);
    });

    testWidgets('does not overflow at 320 px with long amounts',
        (tester) async {
      await tester.pumpWidget(host(
        const ComparisonRow(
          id: 'c1',
          label: 'Una categoría con un nombre realmente largo de verdad',
          colorHex: '#4CBB7A',
          before: 12345678.90,
          after: 98765432.10,
          difference: 86419753.20,
          percentChange: 700.0,
          budget: 99999999.99,
        ),
        width: 320,
      ));

      expect(tester.takeException(), isNull);
    });
  });
}
