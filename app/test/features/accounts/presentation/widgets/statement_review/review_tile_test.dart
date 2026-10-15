import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/scanned_movement.dart';
import 'package:luma/features/accounts/presentation/widgets/statement_review/review_tile.dart';

StatementReviewItem item({String? description = 'Mercadona'}) {
  return StatementReviewItem(
    ScannedMovement(
      type: 'expense',
      amount: 21.05,
      date: DateTime(2026, 8, 30),
      description: description,
    ),
  );
}

void main() {
  Widget host(
    StatementReviewItem item, {
    ValueChanged<bool?>? onToggle,
    ValueChanged<bool?>? onToggleTransfer,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: StatementReviewTile(
          item: item,
          currency: 'USD',
          onToggle: onToggle ?? (_) {},
          onToggleTransfer: onToggleTransfer ?? (_) {},
          onEdit: () {},
        ),
      ),
    );
  }

  testWidgets('shows no transfer alert for a regular line', (tester) async {
    await tester.pumpWidget(host(item()));

    expect(find.text('Registrar como transferencia'), findsNothing);
  });

  testWidgets('shows the alert and a checked box for a transfer',
      (tester) async {
    final transfer = item(description: 'Transferencia a Juan')
      ..isTransfer = true
      ..asTransfer = true;

    await tester.pumpWidget(host(transfer));

    expect(find.textContaining('transferencia entre cuentas'), findsOneWidget);
    final box = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Registrar como transferencia'),
    );
    expect(box.value, isTrue);
  });

  testWidgets('reports the change when the transfer box is toggled',
      (tester) async {
    bool? changed;
    final transfer = item(description: 'Transferencia')
      ..isTransfer = true
      ..asTransfer = true;

    await tester.pumpWidget(
      host(transfer, onToggleTransfer: (value) => changed = value),
    );
    await tester.tap(find.text('Registrar como transferencia'));

    expect(changed, isFalse);
  });

  testWidgets('an out-of-period line cannot be selected', (tester) async {
    final outside = item()
      ..inRange = false
      ..selected = false;

    await tester.pumpWidget(host(outside, onToggle: (_) => fail('toggled')));

    expect(find.text('Fuera del período'), findsOneWidget);
    final box = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(box.value, isFalse);
    expect(box.onChanged, isNull);
  });

  testWidgets('an out-of-period transfer shows no transfer alert',
      (tester) async {
    final outside = item(description: 'Transferencia')
      ..isTransfer = true
      ..inRange = false;

    await tester.pumpWidget(host(outside));

    expect(find.text('Registrar como transferencia'), findsNothing);
  });
}
