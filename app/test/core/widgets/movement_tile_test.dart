import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/theme/app_colors.dart';
import 'package:luma/core/widgets/cards/movement_tile.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    required MovementLeading leading,
    String? title = 'Supermercado',
    Widget? trailing,
    String? warning,
    EdgeInsetsGeometry? padding,
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
            warning: warning,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  testWidgets('shows a hollow ring for a movement without category',
      (tester) async {
    await pumpTile(tester, leading: const MovementLeading.uncategorized());

    final ring = tester.widget<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
    );
    final decoration = ring.decoration! as BoxDecoration;
    expect(decoration.color, isNull);
    expect(decoration.border, isNotNull);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('labels the ring for screen readers', (tester) async {
    await pumpTile(tester, leading: const MovementLeading.uncategorized());

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Sin categoría',
      ),
      findsOneWidget,
    );
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

  testWidgets('shows a warning under the subtitle', (tester) async {
    await pumpTile(
      tester,
      leading: const MovementLeading.category(color: Colors.orange),
      warning: 'Posible duplicado',
    );

    final subtitle = tester.getRect(find.text('Comida · 19/10/2026'));
    final warning = tester.getRect(find.text('Posible duplicado'));
    expect(warning.top, greaterThanOrEqualTo(subtitle.bottom));
    final text = tester.widget<Text>(find.text('Posible duplicado'));
    expect(text.style?.color, AppColors.authExpense);
  });

  testWidgets('shows no warning by default', (tester) async {
    await pumpTile(
      tester,
      leading: const MovementLeading.category(color: Colors.orange),
    );

    expect(find.text('Posible duplicado'), findsNothing);
  });

  testWidgets('uses the given padding', (tester) async {
    await pumpTile(
      tester,
      leading: const MovementLeading.category(color: Colors.orange),
      padding: const EdgeInsets.symmetric(vertical: 8),
    );

    final tile = tester.getRect(find.byType(MovementTile));
    final leading = tester.getRect(find.byType(MovementLeading));
    expect(leading.left, tile.left);
  });
}
