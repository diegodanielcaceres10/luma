import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import 'dashboard_tab.dart';

/// Ruta '/': el Dashboard. Conecta sus acciones con el resto de las
/// pantallas, que son rutas propias abiertas con `context.push` (ver
/// router.dart).
class HomeBranchScreen extends StatelessWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;

  const HomeBranchScreen({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.monthlyBalanceViewModel,
    required this.invoiceViewModel,
    required this.serviceViewModel,
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
      serviceViewModel: serviceViewModel,
      onSeeAllMovements: () => context.push('/movements'),
      onOpenMonthlyBalances: () => context.push('/monthly-balance'),
      onOpenAddTransaction: (type) => context.push('/add-transaction/$type'),
      onGoToAccounts: () => context.push('/accounts/new'),
      onManageAccounts: () => context.push('/accounts-overview'),
      onGoToInvoices: () => context.push('/invoices?filter=pending'),
      onGoToTransfers: () => context.push('/transfer'),
    );
  }
}
