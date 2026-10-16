import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/widgets/input_text_field.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  group('InputTextField', () {
    testWidgets('shows the label above the field when given', (tester) async {
      await tester.pumpWidget(
        host(InputTextField(controller: controller, label: 'Nombre')),
      );

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders only the field without a label', (tester) async {
      await tester.pumpWidget(host(InputTextField(controller: controller)));

      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(InputTextField),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });

    testWidgets('uses a smaller label style when compact', (tester) async {
      await tester.pumpWidget(
        host(
          InputTextField(
            controller: controller,
            label: 'Nombre',
            compact: true,
          ),
        ),
      );

      expect(tester.widget<Text>(find.text('Nombre')).style?.fontSize, 13);
    });

    testWidgets('shows hintText and helperText when given', (tester) async {
      await tester.pumpWidget(
        host(
          InputTextField(
            controller: controller,
            hintText: 'Ej: Comida',
            helperText: 'Máximo 20 caracteres',
          ),
        ),
      );

      expect(find.text('Ej: Comida'), findsOneWidget);
      expect(find.text('Máximo 20 caracteres'), findsOneWidget);
    });

    testWidgets('shows no helper text by default', (tester) async {
      await tester.pumpWidget(host(InputTextField(controller: controller)));

      expect(find.text('Máximo 20 caracteres'), findsNothing);
    });

    testWidgets('writes typed text into the controller and calls onChanged',
        (tester) async {
      String? changed;
      await tester.pumpWidget(
        host(
          InputTextField(
            controller: controller,
            onChanged: (value) => changed = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'hola');

      expect(controller.text, 'hola');
      expect(changed, 'hola');
    });

    testWidgets('shows the validator message after validate()',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        host(
          Form(
            key: formKey,
            child: InputTextField(
              controller: controller,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
            ),
          ),
        ),
      );
      expect(find.text('Campo obligatorio'), findsNothing);

      final valid = formKey.currentState!.validate();
      await tester.pump();

      expect(valid, isFalse);
      expect(find.text('Campo obligatorio'), findsOneWidget);
    });

    testWidgets('shows no error when the validator accepts the value',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      controller.text = 'ok';
      await tester.pumpWidget(
        host(
          Form(
            key: formKey,
            child: InputTextField(
              controller: controller,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
            ),
          ),
        ),
      );

      final valid = formKey.currentState!.validate();
      await tester.pump();

      expect(valid, isTrue);
      expect(find.text('Campo obligatorio'), findsNothing);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        host(InputTextField(controller: controller, enabled: false)),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('applies inputFormatters to typed text', (tester) async {
      await tester.pumpWidget(
        host(
          InputTextField(
            controller: controller,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'a1b2');

      expect(controller.text, '12');
    });
  });
}
