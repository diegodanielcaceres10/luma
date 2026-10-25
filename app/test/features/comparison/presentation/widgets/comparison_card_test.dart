import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/comparison/presentation/view_models/month_comparison.dart';
import 'package:luma/features/comparison/presentation/widgets/comparison_card.dart';
import 'package:luma/features/comparison/presentation/widgets/comparison_row_tile.dart';

const rows = [
  ComparisonRow(
    id: 'income',
    label: 'Ingresos',
    before: 1000,
    after: 1200,
    difference: 200,
    percentChange: 20,
    tone: ComparisonTone.favorable,
  ),
  ComparisonRow(
    id: 'expenses',
    label: 'Gastos',
    before: 400,
    after: 550,
    difference: 150,
    percentChange: 37.5,
    tone: ComparisonTone.unfavorable,
  ),
];

Widget host({required DateTime before, required DateTime after}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ComparisonCard(
          title: 'Resumen',
          beforeMonth: before,
          afterMonth: after,
          rows: rows,
          currency: 'EUR',
        ),
      ),
    ),
  );
}

void main() {
  group('ComparisonCard', () {
    testWidgets('shows the title and the short month labels', (tester) async {
      await tester.pumpWidget(
        host(before: DateTime(2026, 9), after: DateTime(2026, 10)),
      );

      expect(find.text('Resumen'), findsOneWidget);
      expect(find.text('Sep'), findsOneWidget);
      expect(find.text('Oct'), findsOneWidget);
      expect(find.text('Δ'), findsOneWidget);
    });

    testWidgets('adds the year when the months are in different years',
        (tester) async {
      await tester.pumpWidget(
        host(before: DateTime(2025, 12), after: DateTime(2026, 1)),
      );

      expect(find.text('Dic 25'), findsOneWidget);
      expect(find.text('Ene 26'), findsOneWidget);
    });

    testWidgets('renders one tile per row', (tester) async {
      await tester.pumpWidget(
        host(before: DateTime(2026, 9), after: DateTime(2026, 10)),
      );

      expect(find.byType(ComparisonRowTile), findsNWidgets(2));
      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
    });
  });

  group('shortMonthLabel', () {
    test('covers every month without locale data', () {
      final labels = [
        for (var month = 1; month <= 12; month++)
          shortMonthLabel(DateTime(2026, month), withYear: false),
      ];

      expect(labels, [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ]);
    });

    test('pads the two-digit year', () {
      expect(shortMonthLabel(DateTime(2009, 3), withYear: true), 'Mar 09');
    });
  });
}
