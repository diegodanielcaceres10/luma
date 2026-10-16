import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/theme/app_colors.dart';
import 'package:luma/core/widgets/primary_button.dart';

Widget host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

final filledButton = find.byWidgetPredicate((w) => w is FilledButton);

void main() {
  group('PrimaryButton', () {
    testWidgets('shows the label when not loading', (tester) async {
      await tester.pumpWidget(
        host(PrimaryButton(label: 'Guardar', onPressed: () {})),
      );

      expect(find.text('Guardar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows a spinner instead of the label when loading',
        (tester) async {
      await tester.pumpWidget(
        host(
          PrimaryButton(label: 'Guardar', onPressed: () {}, isLoading: true),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(PrimaryButton(label: 'Guardar', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Guardar'));

      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        host(const PrimaryButton(label: 'Guardar', onPressed: null)),
      );

      expect(tester.widget<FilledButton>(filledButton).onPressed, isNull);
    });

    testWidgets('does not disable itself while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          PrimaryButton(
            label: 'Guardar',
            onPressed: () => taps++,
            isLoading: true,
          ),
        ),
      );

      await tester.tap(filledButton);

      expect(taps, 1);
    });

    testWidgets('renders the icon next to the label when given',
        (tester) async {
      await tester.pumpWidget(
        host(
          PrimaryButton(label: 'Añadir', onPressed: () {}, icon: Icons.add),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Añadir'), findsOneWidget);
      expect(filledButton, findsOneWidget);
    });

    testWidgets('renders no icon by default', (tester) async {
      await tester.pumpWidget(
        host(PrimaryButton(label: 'Añadir', onPressed: () {})),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('applies labelStyle to the label', (tester) async {
      await tester.pumpWidget(
        host(
          PrimaryButton(
            label: 'Guardar',
            onPressed: () {},
            labelStyle: const TextStyle(fontSize: 21),
          ),
        ),
      );

      expect(tester.widget<Text>(find.text('Guardar')).style?.fontSize, 21);
    });

    testWidgets('uses the accent background by default', (tester) async {
      await tester.pumpWidget(
        host(PrimaryButton(label: 'Guardar', onPressed: () {})),
      );

      final style = tester.widget<FilledButton>(filledButton).style!;
      expect(style.backgroundColor!.resolve({}), AppColors.authAccent);
    });

    testWidgets('fades the background when disabled and disabledAlpha is set',
        (tester) async {
      await tester.pumpWidget(
        host(
          const PrimaryButton(
            label: 'Guardar',
            onPressed: null,
            disabledAlpha: 0.5,
          ),
        ),
      );

      final style = tester.widget<FilledButton>(filledButton).style!;
      expect(
        style.backgroundColor!.resolve({WidgetState.disabled}),
        AppColors.authAccent.withValues(alpha: 0.5),
      );
    });

    testWidgets('keeps the Material disabled look without disabledAlpha',
        (tester) async {
      await tester.pumpWidget(
        host(const PrimaryButton(label: 'Guardar', onPressed: null)),
      );

      final style = tester.widget<FilledButton>(filledButton).style!;
      expect(style.backgroundColor!.resolve({WidgetState.disabled}), isNull);
    });

    testWidgets('rounds the corners when borderRadius is given',
        (tester) async {
      await tester.pumpWidget(
        host(
          PrimaryButton(label: 'Guardar', onPressed: () {}, borderRadius: 12),
        ),
      );

      final style = tester.widget<FilledButton>(filledButton).style!;
      expect(
        style.shape!.resolve({}),
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    });
  });
}
