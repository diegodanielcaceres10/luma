import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/currency_format.dart';
import 'package:luma/features/transactions/presentation/widgets/statistics/summary_cards.dart';

Widget host({required double width}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: const StatisticsSummaryCardsRow(
            income: 1500,
            expenses: 1222.51,
            netResult: 277.49,
            incomeChangePercent: null,
            expenseChangePercent: null,
            netChangePercent: null,
            currency: 'EUR',
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('StatisticsSummaryCardsRow', () {
    testWidgets('labels the third card "Balance"', (tester) async {
      await tester.pumpWidget(host(width: 360));

      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('Balance del mes'), findsNothing);
    });

    testWidgets('shows every amount in full on a narrow width',
        (tester) async {
      await tester.pumpWidget(host(width: 320));

      for (final amount in [1500.0, 1222.51, 277.49]) {
        final finder = find.text(formatCurrency(amount, 'EUR'));
        expect(finder, findsOneWidget);

        final paragraph = tester.renderObject<RenderParagraph>(finder);
        expect(paragraph.didExceedMaxLines, isFalse);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
