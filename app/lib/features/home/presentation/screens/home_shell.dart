import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../monthly_balances/presentation/screens/monthly_balance_tab.dart';
import '../../../monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../../../transactions/presentation/screens/add_transaction_tab.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../../transfers/presentation/screens/transfer_form_tab.dart';
import 'dashboard_tab.dart';

/// FASE 2 y 3 de la migración a rutas (go_router): "Inicio", "Movimientos",
/// "Estadísticas" y "Perfil" son ramas propias de un
/// `StatefulShellRoute.indexedStack` (ver router.dart y
/// app_shell_screen.dart, que ponen el Scaffold/drawer/header/bottomNav
/// compartido). Cuentas, Categorías, Servicios, Facturas y sus
/// formularios ya son rutas propias también, empujadas con `context.push`
/// dentro de esta misma rama (ver router.dart) — por eso ya no viven acá.
///
/// Lo único que queda colgado de la rama "Inicio" con el mecanismo viejo
/// de índice + IndexedStack son el Dashboard y los 3 formularios a los
/// que solo se llega desde ahí (no tienen una pantalla de "listado"
/// propia): agregar saldo inicial del mes, nueva transacción, y
/// transferencia entre cuentas. Migrarlos a rutas propias es la fase
/// siguiente del plan.
const _monthlyBalanceTabIndex = 1;
const _addTransactionTabIndex = 2;
const _transferFormTabIndex = 3;

class HomeBranchScreen extends StatefulWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final InvoiceViewModel invoiceViewModel;

  /// AppShellScreen (el Scaffold compartido) necesita reconstruirse cada
  /// vez que cambia el índice interno de acá — de eso depende si el botón
  /// atrás debe cerrar la app o resolverse acá adentro (el header y el
  /// drawer ya no dependen de esto: Cuentas/Categorías/Servicios/Facturas
  /// pasaron a ser rutas con su propio AppBar).
  final VoidCallback onChanged;

  const HomeBranchScreen({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.monthlyBalanceViewModel,
    required this.invoiceViewModel,
    required this.onChanged,
  });

  @override
  State<HomeBranchScreen> createState() => HomeBranchScreenState();
}

class HomeBranchScreenState extends State<HomeBranchScreen> {
  int _index = 0;

  // Cuentas pendientes de saldo inicial del mes, capturadas al abrir el
  // aviso desde el Dashboard.
  List<Account> _pendingMonthlyBalanceAccounts = [];
  int _monthlyBalanceNonce = 0;

  // Tipo de transacción ('income' | 'expense') que se está creando, y un
  // nonce para forzar un formulario limpio cada vez que se abre.
  String _transactionType = 'expense';
  int _addTransactionNonce = 0;

  // Transferencias: todavía no se guardan, pero el nonce ya deja el
  // formulario listo para cuando se agregue el guardado.
  int _transferFormNonce = 0;

  /// Todo cambio de índice pasa por acá para que AppShellScreen se entere
  /// y se reconstruya (lo necesita para decidir el botón atrás).
  void _update(VoidCallback fn) {
    setState(fn);
    widget.onChanged();
  }

  // ---- API pública para AppShellScreen (el Scaffold compartido) ----

  /// true solo en el Dashboard — es cuándo AppShellScreen puede dejar que
  /// el sistema haga "pop" real (cerrar la app / navegar atrás en Web).
  bool get isDashboard => _index == 0;

  /// Vuelve al Dashboard. Lo usa AppShellScreen tanto cuando se toca
  /// "Inicio" en el bottom nav/drawer (siempre resetea, sin importar en
  /// qué formulario interno se haya quedado) como al volver acá desde
  /// otra rama con el botón atrás.
  void goToDashboard() => _update(() => _index = 0);

  /// Qué hacer cuando el usuario presiona "atrás" (botón físico/gesto en
  /// Android, botón atrás del navegador en Web) estando en esta rama. Si
  /// ya estamos en el Dashboard no hay nada que resolver acá —
  /// AppShellScreen se encarga de qué pasa después.
  void handleBackPress() {
    if (_index != 0) _update(() => _index = 0);
  }

  // ---- El resto es la misma lógica que tenía HomeShell ----

  void _openTransferForm() {
    _update(() {
      _transferFormNonce++;
      _index = _transferFormTabIndex;
    });
  }

  void _closeTransferForm() {
    _update(() => _index = 0);
  }

  void _openMonthlyBalanceForm(List<Account> pendingAccounts) {
    _update(() {
      _pendingMonthlyBalanceAccounts = pendingAccounts;
      _monthlyBalanceNonce++;
      _index = _monthlyBalanceTabIndex;
    });
  }

  void _closeMonthlyBalanceForm() {
    _update(() {
      _pendingMonthlyBalanceAccounts = [];
      _index = 0;
    });
  }

  void _openAddTransactionForm(String type) {
    _update(() {
      _transactionType = type;
      _addTransactionNonce++;
      _index = _addTransactionTabIndex;
    });
  }

  void _closeAddTransactionForm() {
    _update(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(
        authViewModel: widget.authViewModel,
        accountViewModel: widget.accountViewModel,
        transactionViewModel: widget.transactionViewModel,
        categoryViewModel: widget.categoryViewModel,
        monthlyBalanceViewModel: widget.monthlyBalanceViewModel,
        invoiceViewModel: widget.invoiceViewModel,
        onSeeAllMovements: () => StatefulNavigationShell.of(context).goBranch(1),
        onOpenMonthlyBalances: _openMonthlyBalanceForm,
        onOpenAddTransaction: _openAddTransactionForm,
        // Cuentas, vista general y facturas ya son rutas propias — se
        // llega con context.push, no con un índice interno.
        onGoToAccounts: () => context.push('/accounts/new'),
        onManageAccounts: () => context.push('/accounts-overview'),
        onGoToInvoices: () => context.push('/invoices?pending=true'),
        onGoToTransfers: _openTransferForm,
      ),
      MonthlyBalanceTab(
        key: ValueKey('monthly-balance-$_monthlyBalanceNonce'),
        userId: widget.authViewModel.userId ?? '',
        pendingAccounts: _pendingMonthlyBalanceAccounts,
        monthlyBalanceViewModel: widget.monthlyBalanceViewModel,
        onDone: _closeMonthlyBalanceForm,
      ),
      AddTransactionTab(
        key: ValueKey('add-transaction-$_addTransactionNonce'),
        type: _transactionType,
        userId: widget.authViewModel.userId ?? '',
        accountViewModel: widget.accountViewModel,
        categoryViewModel: widget.categoryViewModel,
        transactionViewModel: widget.transactionViewModel,
        onDone: _closeAddTransactionForm,
      ),
      TransferFormTab(
        key: ValueKey('transfer-form-$_transferFormNonce'),
        userId: widget.authViewModel.userId,
        accountViewModel: widget.accountViewModel,
        transactionViewModel: widget.transactionViewModel,
        onDone: _closeTransferForm,
      ),
    ];

    return IndexedStack(index: _index, children: tabs);
  }
}
