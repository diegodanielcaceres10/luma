import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/scanned_movement.dart';
import 'package:luma/features/accounts/presentation/widgets/pending_movements_section.dart';
import 'package:luma/features/accounts/presentation/widgets/statement_review_sheet.dart';

ScannedMovement scanned(
  String description, {
  double amount = 10,
  DateTime? date,
}) {
  return ScannedMovement(
    type: 'expense',
    amount: amount,
    date: date ?? DateTime(2026, 8, 10),
    description: description,
  );
}

void main() {
  List<PendingMovement>? result;
  var closed = false;

  final august = DateTimeRange(
    start: DateTime(2026, 8),
    end: DateTime(2026, 8, 31),
  );

  Future<void> open(
    WidgetTester tester,
    List<ScannedMovement> movements,
  ) async {
    result = null;
    closed = false;
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showStatementReviewSheet(
                  context,
                  movements: movements,
                  currency: 'USD',
                  dateRange: august,
                  known: const [],
                );
                closed = true;
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

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  }

  testWidgets('returns the selected lines as regular movements',
      (tester) async {
    await open(tester, [scanned('Mercadona'), scanned('Expavaxar')]);

    await confirm(tester);

    expect(result, hasLength(2));
    expect(result!.every((m) => m is CategoryPendingMovement), isTrue);
  });

  testWidgets('a line outside the period stays out and cannot be added',
      (tester) async {
    await open(tester, [
      scanned('Dentro'),
      scanned('Fuera', date: DateTime(2026, 9, 3)),
    ]);

    expect(find.text('Fuera del período'), findsOneWidget);
    final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(boxes.map((b) => b.value), [true, false]);
    expect(boxes[1].onChanged, isNull);

    await confirm(tester);

    expect(result!.map((m) => m.description), ['Dentro']);
  });

  testWidgets('editing a line changes only its description', (tester) async {
    await open(tester, [scanned('Mercadona', amount: 21.05)]);

    await tester.tap(find.text('Mercadona'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Supermercado');
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    await confirm(tester);

    final movement = result!.single;
    expect(movement.description, 'Supermercado');
    expect(movement.amount, -21.05);
    expect(movement.date, DateTime(2026, 8, 10));
  });

  testWidgets('a "Transferencia" line is flagged and added as a transfer',
      (tester) async {
    await open(tester, [scanned('Transferencia a Juan', amount: 50)]);

    expect(find.text('Registrar como transferencia'), findsOneWidget);

    await confirm(tester);

    final movement = result!.single;
    expect(movement, isA<TransferPendingMovement>());
    expect(movement.amount, -50);
  });

  testWidgets('unchecking the alert adds the line as a regular movement',
      (tester) async {
    await open(tester, [scanned('Transferencia a Juan', amount: 50)]);

    await tester.tap(find.text('Registrar como transferencia'));
    await tester.pump();
    await confirm(tester);

    expect(result!.single, isA<CategoryPendingMovement>());
  });

  testWidgets('editing the description to mention a transfer flags the line',
      (tester) async {
    await open(tester, [scanned('Mercadona')]);
    expect(find.text('Registrar como transferencia'), findsNothing);

    await tester.tap(find.text('Mercadona'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Transferencia Maria');
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar como transferencia'), findsOneWidget);
  });

  testWidgets('editing the description to drop the word clears the flag',
      (tester) async {
    await open(tester, [scanned('Transferencia Maria')]);

    await tester.tap(find.text('Transferencia Maria'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alquiler');
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar como transferencia'), findsNothing);
    await confirm(tester);
    expect(result!.single, isA<CategoryPendingMovement>());
  });

  testWidgets('an out-of-period line cannot be opened for correction',
      (tester) async {
    await open(tester, [
      scanned('Fuera', date: DateTime(2026, 9, 3)),
    ]);

    await tester.tap(find.text('Fuera'));
    await tester.pumpAndSettle();

    expect(find.text('Corregir descripción'), findsNothing);
  });
}
