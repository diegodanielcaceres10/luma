import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import 'dashboard_tab.dart';

/// MIGRACIÓN A RUTAS COMPLETA para la rama "Inicio": Cuentas, Categorías,
/// Servicios, Facturas, saldo inicial del mes, nueva transacción y
/// transferencia ya son todas rutas propias, empujadas con `context.push`
/// desde acá o desde el Dashboard (ver router.dart). Lo único que queda
/// en esta rama es, directamente, el Dashboard — ya no hace falta ningún
/// índice ni `IndexedStack` a mano.
class HomeBranchScreen extends StatelessWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final InvoiceViewModel invoiceViewModel;

  const HomeBranchScreen({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.monthlyBalanceViewModel,
    required this.invoiceViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardTab(
      authViewModel: authViewModel,
      accountViewModel: accountViewModel,
      transactionViewModel: transactionViewModel,
      categoryViewModel: categoryViewModel,
      monthlyBalanceViewModel: monthlyBalanceViewModel,
      invoiceViewModel: invoiceViewModel,
      onSeeAllMovements: () => StatefulNavigationShell.of(context).goBranch(1),
      onOpenMonthlyBalances: (pendingAccounts) =>
          context.push('/monthly-balance'),
      onOpenAddTransaction: (type) => context.push('/add-transaction/$type'),
      onGoToAccounts: () => context.push('/accounts/new'),
      onManageAccounts: () => context.push('/accounts-overview'),
      onGoToInvoices: () => context.push('/invoices?pending=true'),
      onGoToTransfers: () => context.push('/transfer'),
    );
  }
}
