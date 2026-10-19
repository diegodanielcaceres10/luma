import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/theme/app_colors.dart';
import 'package:luma/core/utils/date_format.dart';
import 'package:luma/features/accounts/presentation/widgets/pending_movements/movements_list.dart';
import 'package:luma/features/accounts/presentation/widgets/pending_movements/pending_movement.dart';
import 'package:luma/features/accounts/presentation/widgets/pending_movements/pending_movements_read_only_list.dart';
import 'package:luma/features/categories/data/models/category.dart';
import 'package:luma/features/invoices/data/models/invoice.dart';

void main() {
  final date = DateTime(2026, 10, 13);

  const food = Category(
    id: 'c1',
    name: 'Comida',
    type: 'expense',
    color: '#F59E0B',
  );

  CategoryPendingMovement categoryMovement({
    double amount = -21.05,
    String? description,
    Category? category = food,
  }) {
    return CategoryPendingMovement(
      amount: amount,
      date: date,
      type: amount > 0 ? 'income' : 'expense',
      category: category,
      description: description,
    );
  }

  Finder dotWithColor(Color color) => find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle &&
            (widget.decoration! as BoxDecoration).color == color,
      );

  Future<void> pumpEditable(
    WidgetTester tester,
    List<PendingMovement> movements, {
    bool enabled = true,
    void Function(PendingMovement)? onEdit,
    void Function(PendingMovement)? onDelete,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MovementsList(
              movements: movements,
              currency: 'EUR',
              enabled: enabled,
              onEdit: onEdit ?? (_) {},
              onDelete: onDelete ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpReadOnly(
    WidgetTester tester,
    List<PendingMovement> movements,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PendingMovementsReadOnlyList(
              movements: movements,
              currency: 'EUR',
            ),
          ),
        ),
      ),
    );
  }

  group('MovementsList', () {
    testWidgets('shows the description, then category and date',
        (tester) async {
      await pumpEditable(
        tester,
        [categoryMovement(description: 'Supermercado')],
      );

      expect(find.text('Supermercado'), findsOneWidget);
      expect(find.text('Comida · ${formatDate(date)}'), findsOneWidget);
    });

    testWidgets('shows "Sin descripción" in italics instead of the category',
        (tester) async {
      await pumpEditable(tester, [categoryMovement()]);

      final title = tester.widget<Text>(find.text('Sin descripción'));
      expect(title.style?.fontStyle, FontStyle.italic);
      expect(find.text('Comida'), findsNothing);
    });

    testWidgets('marks a category movement with its color dot',
        (tester) async {
      await pumpEditable(tester, [categoryMovement()]);

      expect(dotWithColor(const Color(0xFFF59E0B)), findsOneWidget);
    });

    testWidgets('uses a neutral dot and "Sin categoría" without a category',
        (tester) async {
      await pumpEditable(tester, [categoryMovement(category: null)]);

      expect(dotWithColor(AppColors.authTextSecondary), findsOneWidget);
      expect(find.text('Sin categoría · ${formatDate(date)}'), findsOneWidget);
    });

    testWidgets('marks a transfer with its icon and names the other account',
        (tester) async {
      await pumpEditable(tester, [
        TransferPendingMovement(
          amount: -50,
          date: date,
          otherAccountId: 'b',
          otherAccountName: 'Cuenta Extra',
        ),
      ]);

      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
      expect(
        find.text('Transferencia a Cuenta Extra · ${formatDate(date)}'),
        findsOneWidget,
      );
    });

    testWidgets('marks an invoice with the invoice icon and its service',
        (tester) async {
      await pumpEditable(tester, [
        InvoicePendingMovement(
          amount: -12,
          date: date,
          invoice: const Invoice(
            id: 'i1',
            serviceId: 's1',
            month: 10,
            year: 2026,
            amount: 12,
            paid: false,
          ),
          category: food,
          serviceName: 'Netflix',
        ),
      ]);

      expect(find.byIcon(Icons.request_page_outlined), findsOneWidget);
      expect(
        find.text('Factura · Netflix · ${formatDate(date)}'),
        findsOneWidget,
      );
    });

    testWidgets('colors the amount by sign and shows it for income',
        (tester) async {
      await pumpEditable(tester, [categoryMovement(amount: 30)]);

      final amount = tester.widget<Text>(find.textContaining('+'));
      expect(amount.style?.color, AppColors.authIncome);
    });

    testWidgets('edits and removes through the row buttons', (tester) async {
      final movement = categoryMovement();
      PendingMovement? edited;
      PendingMovement? removed;
      await pumpEditable(
        tester,
        [movement],
        onEdit: (m) => edited = m,
        onDelete: (m) => removed = m,
      );

      await tester.tap(find.byTooltip('Editar'));
      await tester.tap(find.byTooltip('Quitar'));

      expect(edited, same(movement));
      expect(removed, same(movement));
    });

    testWidgets('disables both buttons when the list is disabled',
        (tester) async {
      var calls = 0;
      await pumpEditable(
        tester,
        [categoryMovement()],
        enabled: false,
        onEdit: (_) => calls++,
        onDelete: (_) => calls++,
      );

      await tester.tap(find.byTooltip('Editar'));
      await tester.tap(find.byTooltip('Quitar'));

      expect(calls, 0);
    });

    testWidgets('separates rows with dividers, but not after the last one',
        (tester) async {
      await pumpEditable(tester, [categoryMovement(), categoryMovement()]);

      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('PendingMovementsReadOnlyList', () {
    testWidgets('shows the same row without edit or remove buttons',
        (tester) async {
      await pumpReadOnly(
        tester,
        [categoryMovement(description: 'Supermercado')],
      );

      expect(find.text('Supermercado'), findsOneWidget);
      expect(find.text('Comida · ${formatDate(date)}'), findsOneWidget);
      expect(dotWithColor(const Color(0xFFF59E0B)), findsOneWidget);
      expect(find.byTooltip('Editar'), findsNothing);
      expect(find.byTooltip('Quitar'), findsNothing);
    });

    testWidgets('shows "Sin descripción" in italics', (tester) async {
      await pumpReadOnly(tester, [categoryMovement()]);

      final title = tester.widget<Text>(find.text('Sin descripción'));
      expect(title.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('marks transfers with their icon', (tester) async {
      await pumpReadOnly(tester, [
        TransferPendingMovement(amount: 20, date: date),
      ]);

      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
      expect(find.text('Transferencia · ${formatDate(date)}'), findsOneWidget);
    });
  });
}
