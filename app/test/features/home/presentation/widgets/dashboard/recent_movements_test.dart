import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/theme/app_colors.dart';
import 'package:luma/core/utils/date_format.dart';
import 'package:luma/features/home/presentation/widgets/dashboard/recent_movements.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';

void main() {
  final date = DateTime(2026, 10, 13);

  TransactionEntry movement({
    String id = 'm1',
    String type = 'expense',
    String? description,
    String categoryName = 'Comida',
    String? categoryColor = '#F59E0B',
    String? categoryId = 'c1',
    bool isTransfer = false,
  }) {
    return TransactionEntry(
      id: id,
      type: type,
      amount: 21.05,
      description: description,
      date: date,
      category: TransactionCategory(
        id: categoryId,
        name: categoryName,
        color: categoryColor,
      ),
      account: const TransactionAccount(name: 'Cuenta'),
      isTransfer: isTransfer,
    );
  }

  Future<void> pumpList(
    WidgetTester tester,
    List<TransactionEntry> movements, {
    bool isLoading = false,
    Set<String> servicePaymentIds = const {},
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardRecentMovements(
              isLoading: isLoading,
              movements: movements,
              currency: 'EUR',
              servicePaymentIds: servicePaymentIds,
            ),
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

  testWidgets('shows "Sin descripción" in italics instead of the category',
      (tester) async {
    await pumpList(tester, [movement(description: null)]);

    final title = tester.widget<Text>(find.text('Sin descripción'));
    expect(title.style?.fontStyle, FontStyle.italic);
    // The category appears once, in the second line.
    expect(find.text('${formatDate(date)} · Comida'), findsOneWidget);
    expect(find.text('Comida'), findsNothing);
  });

  testWidgets('shows the description, then category and date',
      (tester) async {
    await pumpList(tester, [movement(description: 'Supermercado')]);

    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.text('${formatDate(date)} · Comida'), findsOneWidget);
  });

  testWidgets('marks regular movements with the category color dot',
      (tester) async {
    await pumpList(tester, [movement(categoryColor: '#F59E0B')]);

    expect(dotWithColor(const Color(0xFFF59E0B)), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
  });

  testWidgets('shows only the date for a movement without category',
      (tester) async {
    await pumpList(
      tester,
      [movement(categoryId: null, categoryName: 'Sin categoría')],
    );

    expect(find.text(formatDate(date)), findsOneWidget);
    expect(find.textContaining('Sin categoría'), findsNothing);
  });

  testWidgets('marks transfers with the transfer icon', (tester) async {
    await pumpList(tester, [movement(isTransfer: true)]);

    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    expect(find.text('${formatDate(date)} · Transferencia'), findsOneWidget);
  });

  testWidgets('marks service payments with the invoice icon', (tester) async {
    await pumpList(
      tester,
      [movement(id: 'paid'), movement(id: 'other')],
      servicePaymentIds: {'paid'},
    );

    expect(find.byIcon(Icons.request_page_outlined), findsOneWidget);
    expect(dotWithColor(const Color(0xFFF59E0B)), findsOneWidget);
  });

  testWidgets('colors the amount by type', (tester) async {
    await pumpList(tester, [movement(type: 'income')]);

    final amount = tester.widget<Text>(find.textContaining('+'));
    expect(amount.style?.color, AppColors.authIncome);
  });

  testWidgets('separates rows with dividers, but not after the last one',
      (tester) async {
    await pumpList(tester, [movement(id: 'a'), movement(id: 'b')]);

    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('shows progress while loading', (tester) async {
    await pumpList(tester, const [], isLoading: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the empty message when there are no movements',
      (tester) async {
    await pumpList(tester, const []);

    expect(find.text('Todavía no hay movimientos este mes.'), findsOneWidget);
  });
}
