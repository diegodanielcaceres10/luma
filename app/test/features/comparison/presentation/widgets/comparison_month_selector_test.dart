import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luma/core/utils/app_clock.dart';
import 'package:luma/features/comparison/presentation/widgets/comparison_month_selector.dart';

Widget host({
  required DateTime before,
  required DateTime after,
  VoidCallback? onSwap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ComparisonMonthSelector(
        before: before,
        after: after,
        onBeforeChanged: (_) {},
        onAfterChanged: (_) {},
        onSwap: onSwap ?? () {},
      ),
    ),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('ComparisonMonthSelector', () {
    testWidgets('labels both months and shows their names', (tester) async {
      await tester.pumpWidget(
        host(before: DateTime(2020, 9), after: DateTime(2020, 10)),
      );

      expect(find.text('Antes'), findsOneWidget);
      expect(find.text('Después'), findsOneWidget);
      expect(find.text('Septiembre 2020'), findsOneWidget);
      expect(find.text('Octubre 2020'), findsOneWidget);
    });

    testWidgets('tapping the swap button calls onSwap', (tester) async {
      var swaps = 0;
      await tester.pumpWidget(
        host(
          before: DateTime(2020, 9),
          after: DateTime(2020, 10),
          onSwap: () => swaps++,
        ),
      );

      await tester.tap(find.byTooltip('Intercambiar meses'));

      expect(swaps, 1);
    });

    testWidgets('marks only the current month with "en curso"',
        (tester) async {
      final now = nowLocal();
      await tester.pumpWidget(
        host(
          before: DateTime(now.year, now.month - 1),
          after: DateTime(now.year, now.month),
        ),
      );

      expect(find.text('en curso'), findsOneWidget);
    });

    testWidgets('shows no "en curso" when both months are past',
        (tester) async {
      await tester.pumpWidget(
        host(before: DateTime(2020, 9), after: DateTime(2020, 10)),
      );

      expect(find.text('en curso'), findsNothing);
    });

    testWidgets('does not overflow at 320 px', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Fixed past months: the test font makes every letter as wide as the
      // font size, and the current month's name changes through the year.
      await tester.pumpWidget(
        host(before: DateTime(2020, 5), after: DateTime(2020, 6)),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
