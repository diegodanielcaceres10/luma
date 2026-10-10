import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/theme/app_colors.dart';
import 'package:luma/core/widgets/secondary_button.dart';

Widget host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

OutlinedButton button(WidgetTester tester) =>
    tester.widget<OutlinedButton>(find.byType(OutlinedButton));

void main() {
  group('SecondaryButton', () {
    testWidgets('shows the label', (tester) async {
      await tester.pumpWidget(
        host(SecondaryButton(label: 'Cancelar', onPressed: () {})),
      );

      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(SecondaryButton(label: 'Cancelar', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Cancelar'));

      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        host(const SecondaryButton(label: 'Cancelar', onPressed: null)),
      );

      expect(button(tester).onPressed, isNull);
    });

    testWidgets('uses the card border color', (tester) async {
      await tester.pumpWidget(
        host(SecondaryButton(label: 'Cancelar', onPressed: () {})),
      );

      final side = button(tester).style!.side!.resolve({});
      expect(side?.color, AppColors.authCardBorder);
    });

    testWidgets('uses the primary text color by default', (tester) async {
      await tester.pumpWidget(
        host(SecondaryButton(label: 'Cancelar', onPressed: () {})),
      );

      final color = button(tester).style!.foregroundColor!.resolve({});
      expect(color, AppColors.authTextPrimary);
    });

    testWidgets('applies a custom foregroundColor', (tester) async {
      await tester.pumpWidget(
        host(
          SecondaryButton(
            label: 'Cancelar',
            onPressed: () {},
            foregroundColor: Colors.red,
          ),
        ),
      );

      final color = button(tester).style!.foregroundColor!.resolve({});
      expect(color, Colors.red);
    });

    testWidgets('applies labelStyle to the label', (tester) async {
      await tester.pumpWidget(
        host(
          SecondaryButton(
            label: 'Cancelar',
            onPressed: () {},
            labelStyle: const TextStyle(fontSize: 19),
          ),
        ),
      );

      expect(tester.widget<Text>(find.text('Cancelar')).style?.fontSize, 19);
    });

    testWidgets('keeps the theme shape without borderRadius', (tester) async {
      await tester.pumpWidget(
        host(SecondaryButton(label: 'Cancelar', onPressed: () {})),
      );

      expect(button(tester).style!.shape, isNull);
    });

    testWidgets('rounds the corners when borderRadius is given',
        (tester) async {
      await tester.pumpWidget(
        host(
          SecondaryButton(
            label: 'Cancelar',
            onPressed: () {},
            borderRadius: 12,
          ),
        ),
      );

      expect(
        button(tester).style!.shape!.resolve({}),
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    });
  });
}
