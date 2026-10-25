import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luma/features/transactions/presentation/widgets/statistics/statistics_header.dart';

Widget host({
  VoidCallback? onCompareMonths,
  VoidCallback? onExportPdf,
  VoidCallback? onExportFullPdf,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: StatisticsHeader(
          selectedMonth: DateTime(2020, 5),
          onMonthChanged: (_) {},
          onCompareMonths: onCompareMonths,
          onExportPdf: onExportPdf,
          onExportFullPdf: onExportFullPdf,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('StatisticsHeader', () {
    testWidgets('shows "Comparar meses" and calls the callback when pressed',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(onCompareMonths: () => taps++));

      expect(find.text('Comparar meses'), findsOneWidget);

      await tester.tap(find.text('Comparar meses'));

      expect(taps, 1);
    });

    testWidgets('hides the button when onCompareMonths is null',
        (tester) async {
      await tester.pumpWidget(host(onExportPdf: () {}));

      expect(find.text('Comparar meses'), findsNothing);
    });

    testWidgets('the compare button does not depend on the export buttons',
        (tester) async {
      await tester.pumpWidget(host(onCompareMonths: () {}));

      expect(find.text('Comparar meses'), findsOneWidget);
      expect(find.text('Exportar PDF'), findsNothing);
      expect(find.text('Exportar PDF completo'), findsNothing);
    });

    testWidgets('keeps the export buttons', (tester) async {
      await tester.pumpWidget(
        host(
          onCompareMonths: () {},
          onExportPdf: () {},
          onExportFullPdf: () {},
        ),
      );

      expect(find.text('Exportar PDF'), findsOneWidget);
      expect(find.text('Exportar PDF completo'), findsOneWidget);
    });

    testWidgets('an export in progress does not block the compare button',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsHeader(
              selectedMonth: DateTime(2020, 5),
              onMonthChanged: (_) {},
              onCompareMonths: () => taps++,
              onExportPdf: () {},
              isExportingPdf: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Comparar meses'));

      expect(taps, 1);
    });
  });
}
