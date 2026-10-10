import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/theme/app_colors.dart';
import 'package:luma/core/widgets/text_action_button.dart';

Widget host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

TextStyle? labelStyle(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style;

void main() {
  group('TextActionButton', () {
    testWidgets('shows the label', (tester) async {
      await tester.pumpWidget(
        host(TextActionButton(label: 'Volver', onPressed: () {})),
      );

      expect(find.text('Volver'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(TextActionButton(label: 'Volver', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Volver'));

      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        host(const TextActionButton(label: 'Volver', onPressed: null)),
      );

      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNull);
    });

    testWidgets('is muted by default', (tester) async {
      await tester.pumpWidget(
        host(TextActionButton(label: 'Volver', onPressed: () {})),
      );

      final style = labelStyle(tester, 'Volver');
      expect(style?.color, AppColors.authTextSecondary);
      expect(style?.fontWeight, isNull);
    });

    testWidgets('applies color and fontWeight to emphasize the action',
        (tester) async {
      await tester.pumpWidget(
        host(
          TextActionButton(
            label: 'Sí',
            onPressed: () {},
            color: AppColors.authAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      final style = labelStyle(tester, 'Sí');
      expect(style?.color, AppColors.authAccent);
      expect(style?.fontWeight, FontWeight.bold);
    });
  });
}
