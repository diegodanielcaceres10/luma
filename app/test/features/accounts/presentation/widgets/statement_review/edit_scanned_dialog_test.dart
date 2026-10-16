import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/presentation/widgets/statement_review/edit_scanned_dialog.dart';

void main() {
  String? result = 'unset';

  Future<void> open(WidgetTester tester, {String? description}) async {
    result = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => EditScannedDialog(description: description),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('only the description can be edited', (tester) async {
    await open(tester, description: 'Expavaxar, Alcobendas Es');

    expect(find.text('Corregir descripción'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Monto'), findsNothing);
    expect(find.text('Fecha'), findsNothing);
    expect(find.textContaining('Categoría'), findsNothing);
    expect(find.text('Expavaxar, Alcobendas Es'), findsOneWidget);
  });

  testWidgets('confirms with "Listo" and returns the trimmed text',
      (tester) async {
    await open(tester, description: 'Viejo');

    expect(find.text('Agregar'), findsNothing);
    await tester.enterText(find.byType(TextField), '  Nuevo nombre ');
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(result, 'Nuevo nombre');
  });

  testWidgets('returns an empty text when the description is cleared',
      (tester) async {
    await open(tester, description: 'Viejo');

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(result, '');
  });

  testWidgets('returns nothing when cancelled', (tester) async {
    await open(tester, description: 'Viejo');

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
