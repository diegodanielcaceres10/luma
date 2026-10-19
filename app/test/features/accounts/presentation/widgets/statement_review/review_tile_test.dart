import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/theme/app_colors.dart';
import 'package:luma/core/utils/date_format.dart';
import 'package:luma/features/accounts/data/models/scanned_movement.dart';
import 'package:luma/features/accounts/presentation/widgets/statement_review/review_tile.dart';

final _date = DateTime(2026, 8, 30);

StatementReviewItem item({
  String? description = 'Mercadona',
  String type = 'expense',
  DateTime? date,
  bool withDate = true,
}) {
  return StatementReviewItem(
    ScannedMovement(
      type: type,
      amount: 21.05,
      date: withDate ? (date ?? _date) : null,
      description: description,
    ),
  );
}

void main() {
  Widget host(
    StatementReviewItem item, {
    ValueChanged<bool?>? onToggle,
    VoidCallback? onEdit,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: StatementReviewTile(
          item: item,
          currency: 'USD',
          onToggle: onToggle ?? (_) {},
          onEdit: onEdit ?? () {},
        ),
      ),
    );
  }

  testWidgets('shows the description, the date and the amount',
      (tester) async {
    await tester.pumpWidget(host(item()));

    expect(find.text('Mercadona'), findsOneWidget);
    expect(find.text(formatDate(_date)), findsOneWidget);
    expect(find.textContaining('21'), findsOneWidget);
  });

  testWidgets('shows no category, which is chosen later', (tester) async {
    await tester.pumpWidget(host(item()));

    expect(find.textContaining('Sin categoría'), findsNothing);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('shows no leading icon or dot besides the checkbox',
      (tester) async {
    await tester.pumpWidget(host(item()));

    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsNothing);
  });

  testWidgets('shows "Sin descripción" in italics when there is none',
      (tester) async {
    await tester.pumpWidget(host(item(description: null)));

    final title = tester.widget<Text>(find.text('Sin descripción'));
    expect(title.style?.fontStyle, FontStyle.italic);
  });

  testWidgets('shows "Sin fecha" when the line has no date', (tester) async {
    await tester.pumpWidget(host(item(withDate: false)));

    expect(find.text('Sin fecha'), findsOneWidget);
  });

  testWidgets('colors the amount by type and shows the sign for income',
      (tester) async {
    await tester.pumpWidget(host(item(type: 'income')));

    final amount = tester.widget<Text>(find.textContaining('+'));
    expect(amount.style?.color, AppColors.authIncome);
  });

  testWidgets('a line with a transfer description is a regular line',
      (tester) async {
    await tester.pumpWidget(host(item(description: 'Transferencia a Juan')));

    expect(find.text('Registrar como transferencia'), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsNothing);
  });

  testWidgets('reports the change when the line is toggled', (tester) async {
    bool? changed;

    await tester.pumpWidget(host(item(), onToggle: (value) => changed = value));
    await tester.tap(find.byType(Checkbox));

    expect(changed, isTrue);
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

  testWidgets('flags a possible duplicate', (tester) async {
    final duplicate = item()..duplicate = true;

    await tester.pumpWidget(host(duplicate));

    expect(find.text('Posible duplicado'), findsOneWidget);
  });

  testWidgets('the period warning wins over the duplicate one',
      (tester) async {
    final both = item()
      ..inRange = false
      ..duplicate = true;

    await tester.pumpWidget(host(both));

    expect(find.text('Fuera del período'), findsOneWidget);
    expect(find.text('Posible duplicado'), findsNothing);
  });

  testWidgets('tapping a line in the period asks to edit it', (tester) async {
    var edits = 0;

    await tester.pumpWidget(host(item(), onEdit: () => edits++));
    await tester.tap(find.text('Mercadona'));

    expect(edits, 1);
  });

  testWidgets('tapping an out-of-period line does not ask to edit it',
      (tester) async {
    var edits = 0;
    final outside = item()..inRange = false;

    await tester.pumpWidget(host(outside, onEdit: () => edits++));
    await tester.tap(find.text('Mercadona'));

    expect(edits, 0);
  });
}
