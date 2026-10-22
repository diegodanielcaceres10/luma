import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/account.dart';
import 'package:luma/features/accounts/presentation/view_models/account_view_model.dart';
import 'package:luma/features/accounts/presentation/widgets/pending_movements/add_invoice_dialog.dart';
import 'package:luma/features/accounts/presentation/widgets/pending_movements/add_movement_dialog.dart';
import 'package:luma/features/accounts/presentation/widgets/pending_movements/add_transfer_dialog.dart';
import 'package:luma/features/accounts/presentation/widgets/pending_movements/pending_movement.dart';
import 'package:luma/features/auth/presentation/view_models/preferences_view_model.dart';
import 'package:luma/features/categories/data/models/category.dart';
import 'package:luma/features/categories/data/repositories/category_repository.dart';
import 'package:luma/features/categories/presentation/view_models/category_view_model.dart';
import 'package:luma/features/invoices/data/models/invoice.dart';

import '../../../../../helpers/fakes.dart';

/// The dialogs only read the view model's in-memory list, never the
/// repository.
class _UnusedCategoryRepository implements CategoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

void main() {
  final date = DateTime(2026, 10, 3);
  const category = Category(id: 'c1', name: 'Comida', type: 'expense');
  const invoice = Invoice(
    id: 'i1',
    serviceId: 's1',
    month: 10,
    year: 2026,
    amount: 20,
    paid: false,
  );
  final current = Account(
    id: 'a1',
    name: 'Cuenta 1',
    balance: 0,
    isActive: true,
    balanceUpdatedAt: DateTime(2026, 10, 1),
  );
  final other = Account(
    id: 'a2',
    name: 'Cuenta 2',
    balance: 0,
    isActive: true,
    balanceUpdatedAt: DateTime(2026, 10, 1),
  );

  late CategoryViewModel categories;
  late PreferencesViewModel preferences;
  late AccountViewModel accounts;

  setUp(() {
    categories = CategoryViewModel(_UnusedCategoryRepository());
    preferences = PreferencesViewModel(FakePreferencesRepository());
    final accountRepository = FakeAccountRepository()
      ..accounts = [current, other];
    accounts = AccountViewModel(accountRepository, preferences);
  });

  tearDown(() {
    categories.dispose();
    accounts.dispose();
    preferences.dispose();
  });

  Future<void> show(WidgetTester tester, Widget dialog) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: dialog)));
    // The accounts load asynchronously in the real app; here they are set
    // before the dialog builds.
    await tester.pump();
  }

  Future<void> loadAccounts() => accounts.loadAccounts();

  void expectPrimaryLabel(String label, String absent) {
    expect(
      find.widgetWithText(FilledButton, label),
      findsOneWidget,
    );
    expect(find.text(absent), findsNothing);
  }

  group('AddMovementDialog', () {
    Widget dialog({PendingMovement? initial}) => AddMovementDialog(
          categoryViewModel: categories,
          categoryType: 'expense',
          onSave: (_) {},
          initial: initial,
        );

    testWidgets('says Agregar when adding', (tester) async {
      await show(tester, dialog());

      expectPrimaryLabel('Agregar', 'Listo');
    });

    testWidgets('says Listo when editing', (tester) async {
      await show(
        tester,
        dialog(
          initial: CategoryPendingMovement(
            amount: -0.8,
            date: date,
            type: 'expense',
          ),
        ),
      );

      expectPrimaryLabel('Listo', 'Agregar');
    });
  });

  group('AddTransferDialog', () {
    Widget dialog({PendingMovement? initial}) => AddTransferDialog(
          currentAccount: current,
          accountViewModel: accounts,
          onSave: (_) {},
          initial: initial,
        );

    testWidgets('says Agregar when adding', (tester) async {
      await loadAccounts();
      await show(tester, dialog());

      expectPrimaryLabel('Agregar', 'Listo');
    });

    testWidgets('says Listo when editing', (tester) async {
      await loadAccounts();
      await show(
        tester,
        dialog(
          initial: TransferPendingMovement(
            amount: -5,
            date: date,
            otherAccountId: 'a2',
            otherAccountName: 'Cuenta 2',
          ),
        ),
      );

      expectPrimaryLabel('Listo', 'Agregar');
    });
  });

  group('AddInvoiceDialog', () {
    Widget dialog({PendingMovement? initial}) => AddInvoiceDialog(
          invoice: invoice,
          serviceName: 'Luz',
          category: category,
          onSave: (_) {},
          initial: initial,
        );

    testWidgets('says Agregar when adding', (tester) async {
      await show(tester, dialog());

      expectPrimaryLabel('Agregar', 'Listo');
    });

    testWidgets('says Listo when editing', (tester) async {
      await show(
        tester,
        dialog(
          initial: InvoicePendingMovement(
            amount: -18.5,
            date: date,
            invoice: invoice,
            category: category,
            serviceName: 'Luz',
          ),
        ),
      );

      expectPrimaryLabel('Listo', 'Agregar');
    });
  });
}
