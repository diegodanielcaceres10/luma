import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/theme/app_colors.dart';
import 'package:luma/core/widgets/movement_tile.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    required MovementLeading leading,
    String? title = 'Supermercado',
    Widget? trailing,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovementTile(
            leading: leading,
            title: title,
            subtitle: 'Comida · 19/10/2026',
            amountText: '-21,05 €',
            amountColor: AppColors.authExpense,
            trailing: trailing,
          ),
        ),
      ),
    );
  }

  Finder dotWithColor(Color color) => find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle &&
            (widget.decoration! as BoxDecoration).color == color,
      );

  testWidgets('shows title, category and date line, and amount',
      (tester) async {
    await pumpTile(
      tester,
      leading: const MovementLeading.category(color: Colors.orange),
    );

    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.text('Comida · 19/10/2026'), findsOneWidget);
    expect(find.text('-21,05 €'), findsOneWidget);
  });

  testWidgets('shows a dot with the category color as leading',
      (tester) async {
    await pumpTile(
      tester,
      leading: const MovementLeading.category(color: Colors.orange),
    );

    expect(dotWithColor(Colors.orange), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('shows the transfer icon as leading', (tester) async {
    await pumpTile(tester, leading: const MovementLeading.transfer());

    final icon = tester.widget<Icon>(find.byIcon(Icons.swap_horiz_rounded));
    expect(icon.semanticLabel, 'Transferencia');
  });

  testWidgets('shows the invoice icon as leading for service payments',
      (tester) async {
    await pumpTile(tester, leading: const MovementLeading.servicePayment());

    final icon = tester.widget<Icon>(find.byIcon(Icons.request_page_outlined));
    expect(icon.semanticLabel, 'Pago de servicio');
  });

  testWidgets('shows "Sin descripción" in italics when there is no title',
      (tester) async {
    await pumpTile(
      tester,
      title: null,
      leading: const MovementLeading.category(color: Colors.orange),
    );

    final text = tester.widget<Text>(find.text('Sin descripción'));
    expect(text.style?.fontStyle, FontStyle.italic);
  });

  testWidgets('treats a blank title like a missing one', (tester) async {
    await pumpTile(
      tester,
      title: '',
      leading: const MovementLeading.category(color: Colors.orange),
    );

    expect(find.text('Sin descripción'), findsOneWidget);
  });

  testWidgets('does not italicize a real description', (tester) async {
    await pumpTile(
      tester,
      leading: const MovementLeading.category(color: Colors.orange),
    );

    final text = tester.widget<Text>(find.text('Supermercado'));
    expect(text.style?.fontStyle, isNot(FontStyle.italic));
  });

  testWidgets('shows the trailing widget after the amount', (tester) async {
    await pumpTile(
      tester,
      leading: const MovementLeading.category(color: Colors.orange),
      trailing: const Icon(Icons.more_vert_rounded),
    );

    final amount = tester.getRect(find.text('-21,05 €'));
    final trailing = tester.getRect(find.byIcon(Icons.more_vert_rounded));
    expect(trailing.left, greaterThan(amount.right));
  });
}
