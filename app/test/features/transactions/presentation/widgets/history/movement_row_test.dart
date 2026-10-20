import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/theme/app_colors.dart';
import 'package:luma/core/utils/date_format.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/presentation/widgets/history/movement_row.dart';

void main() {
  final date = DateTime(2026, 10, 19);

  TransactionEntry movement({
    String type = 'expense',
    String? description = 'Supermercado',
    String? categoryColor = '#F59E0B',
    String? categoryId = 'c1',
    bool isTransfer = false,
  }) {
    return TransactionEntry(
      id: 'm1',
      type: type,
      amount: 21.05,
      description: description,
      date: date,
      category: TransactionCategory(
        id: categoryId,
        name: categoryId == null ? 'Sin categoría' : 'Comida',
        color: categoryColor,
      ),
      account: const TransactionAccount(name: 'Cuenta'),
      isTransfer: isTransfer,
    );
  }

  Future<void> pumpRow(
    WidgetTester tester,
    TransactionEntry entry, {
    bool isServicePayment = false,
    bool isDeleting = false,
    VoidCallback? onActions,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionMovementRow(
            movement: entry,
            currency: 'EUR',
            showDivider: true,
            isServicePayment: isServicePayment,
            isDeleting: isDeleting,
            onActions: onActions,
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

  testWidgets('shows description, then date and category', (tester) async {
    await pumpRow(tester, movement());

    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.text('${formatDate(date)} · Comida'), findsOneWidget);
  });

  testWidgets('shows only the date and a hollow ring without category',
      (tester) async {
    await pumpRow(tester, movement(categoryId: null, categoryColor: null));

    expect(find.text(formatDate(date)), findsOneWidget);
    expect(find.textContaining('Sin categoría'), findsNothing);
    expect(find.textContaining('·'), findsNothing);
    expect(dotWithColor(AppColors.authTextSecondary), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Sin categoría',
      ),
      findsOneWidget,
    );
  });

  testWidgets('marks a regular movement with a dot in the category color',
      (tester) async {
    await pumpRow(tester, movement(categoryColor: '#F59E0B'));

    expect(dotWithColor(const Color(0xFFF59E0B)), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
  });

  testWidgets('falls back to a neutral dot when the category has no color',
      (tester) async {
    await pumpRow(tester, movement(categoryColor: null));

    expect(dotWithColor(AppColors.authTextSecondary), findsOneWidget);
  });

  testWidgets('marks a transfer with its icon and labels it as such',
      (tester) async {
    await pumpRow(tester, movement(isTransfer: true));

    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    expect(find.text('${formatDate(date)} · Transferencia'), findsOneWidget);
  });

  testWidgets('marks a service payment with the invoice icon',
      (tester) async {
    await pumpRow(tester, movement(), isServicePayment: true);

    expect(find.byIcon(Icons.request_page_outlined), findsOneWidget);
    expect(find.text('${formatDate(date)} · Comida'), findsOneWidget);
  });

  testWidgets('shows "Sin descripción" in italics when there is none',
      (tester) async {
    await pumpRow(tester, movement(description: null));

    final text = tester.widget<Text>(find.text('Sin descripción'));
    expect(text.style?.fontStyle, FontStyle.italic);
  });

  testWidgets('colors the amount by type and shows its sign', (tester) async {
    await pumpRow(tester, movement(type: 'income'));

    final text = tester.widget<Text>(find.textContaining('+'));
    expect(text.style?.color, AppColors.authIncome);
  });

  testWidgets('opens the actions menu', (tester) async {
    var opened = 0;
    await pumpRow(tester, movement(), onActions: () => opened++);

    await tester.tap(find.byTooltip('Opciones del movimiento'));

    expect(opened, 1);
  });

  testWidgets('shows progress instead of the menu while deleting',
      (tester) async {
    await pumpRow(tester, movement(), isDeleting: true, onActions: () {});

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Opciones del movimiento'), findsNothing);
  });
}
