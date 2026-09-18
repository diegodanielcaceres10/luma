import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/screens/account_form_tab.dart';
import '../../../accounts/presentation/screens/accounts_overview_tab.dart';
import '../../../accounts/presentation/screens/accounts_tab.dart';
import '../../../accounts/presentation/screens/update_balance_tab.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/screens/categories_tab.dart';
import '../../../categories/presentation/screens/category_form_tab.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/screens/invoice_form_tab.dart';
import '../../../invoices/presentation/screens/invoices_tab.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../monthly_balances/presentation/screens/monthly_balance_tab.dart';
import '../../../monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../../../services/data/models/service.dart';
import '../../../services/presentation/screens/service_form_tab.dart';
import '../../../services/presentation/screens/services_tab.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/presentation/screens/add_transaction_tab.dart';
import '../../../transactions/presentation/screens/movements_tab.dart';
import '../../../transactions/presentation/screens/statistics_tab.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../../transfers/presentation/screens/transfer_form_tab.dart';
import '../widgets/luma_header.dart';
import 'dashboard_tab.dart';

/// Accesos compartidos entre el bottom nav y el drawer del menú hamburguesa.
const _navItems = [
  (Icons.home_rounded, 'Inicio'),
  (Icons.trending_up_rounded, 'Movimientos'),
  (Icons.bar_chart_rounded, 'Estadísticas'),
  (Icons.person_outline_rounded, 'Perfil'),
];

/// Pestañas a las que solo se llega desde el drawer o desde otra pestaña,
/// sin entrada propia en el bottom nav.
const _accountsTabIndex = 4;
const _accountFormTabIndex = 5;
const _categoriesTabIndex = 6;
const _categoryFormTabIndex = 7;
const _monthlyBalanceTabIndex = 8;
const _addTransactionTabIndex = 9;
const _servicesTabIndex = 10;
const _serviceFormTabIndex = 11;
const _invoicesTabIndex = 12;
const _invoiceFormTabIndex = 13;
const _transferFormTabIndex = 14;
const _accountsOverviewTabIndex = 15;
const _updateBalanceTabIndex = 16;

class HomeShell extends StatefulWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final ServiceViewModel serviceViewModel;
  final InvoiceViewModel invoiceViewModel;

  const HomeShell({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.monthlyBalanceViewModel,
    required this.serviceViewModel,
    required this.invoiceViewModel,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _movementsLoaded = false;

  // Cuenta que se está editando en la pestaña de formulario; null = alta.
  Account? _editingAccount;
  int _accountFormNonce = 0;

  // A qué pestaña volver al cerrar el formulario de cuenta: la vieja lista
  // (drawer) o la nueva vista general (ícono de gerenciamiento del
  // Dashboard), según desde dónde se abrió. Si se abre desde cualquier otro
  // lado (ej. el aviso "no tenés cuentas" del Dashboard), cae a la lista.
  int _accountFormReturnIndex = _accountsTabIndex;

  // Cuenta cuyo saldo se está actualizando desde la nueva pantalla
  // "Actualizar saldo" (ícono de sincronización en cada tarjeta de
  // AccountsOverviewTab); null hasta que se abre por primera vez.
  Account? _updatingBalanceAccount;

  // Categoría que se está editando; null = alta.
  Category? _editingCategory;
  String _categoryInitialType = 'expense';
  int _categoryFormNonce = 0;

  // Cuentas pendientes de saldo inicial del mes, capturadas al abrir el
  // aviso desde el Dashboard.
  List<Account> _pendingMonthlyBalanceAccounts = [];
  int _monthlyBalanceNonce = 0;

  // Tipo de transacción ('income' | 'expense') que se está creando, y un
  // nonce para forzar un formulario limpio cada vez que se abre.
  String _transactionType = 'expense';
  int _addTransactionNonce = 0;

  // Servicio que se está editando; null = alta.
  Service? _editingService;
  int _serviceFormNonce = 0;

  // Facturas: por ahora solo se crean, así que el form no tiene
  // "editingInvoice" — el nonce alcanza para forzar un formulario limpio
  // cada vez que se abre.
  int _invoiceFormNonce = 0;

  // Al entrar a Facturas desde la quick action "Facturas por pagar" del
  // Dashboard, forzamos un InvoicesTab nuevo (via key con este nonce) que
  // arranca con el filtro "Pendientes" aplicado — la pestaña normal
  // (drawer/bottom nav) no lo toca y conserva el filtro que el usuario
  // tenía elegido.
  int _invoicesNonce = 0;
  bool _invoicesInitialPendingFilter = false;

  // Transferencias: todavía no se guardan, pero el nonce ya deja el
  // formulario listo para cuando se agregue el guardado.
  int _transferFormNonce = 0;

  void _onTabTap(int index) {
    setState(() => _index = index);

    // Carga perezosa: el historial completo de transacciones recién se
    // pide la primera vez que se entra a "Movimientos", no al arrancar.
    if (index == 1 && !_movementsLoaded) {
      _movementsLoaded = true;
      widget.transactionViewModel.loadAllTransactions();
    }
  }

  void _openTransferForm() {
    setState(() {
      _transferFormNonce++;
      _index = _transferFormTabIndex;
    });
  }

  void _closeTransferForm() {
    setState(() {
      _index = 0; // Vuelve a "Inicio", único lugar desde donde se abre.
    });
  }

  // Vista general de "Cuentas" (prototipo), a la que se llega desde el
  // ícono de gerenciamiento en la BalanceCard del Dashboard. Al no tener
  // formulario propio, "atrás" vuelve a "Inicio" por el caso default de
  // _handleBackNavigation.
  void _openAccountsOverview() {
    setState(() => _index = _accountsOverviewTabIndex);
  }

  // Pantalla "Actualizar saldo", a la que se llega desde el ícono de
  // sincronización de cada tarjeta en AccountsOverviewTab. Siempre vuelve
  // a esa vista, único lugar desde donde se abre.
  void _openUpdateBalance(Account account) {
    setState(() {
      _updatingBalanceAccount = account;
      _index = _updateBalanceTabIndex;
    });
  }

  void _closeUpdateBalance() {
    setState(() {
      _updatingBalanceAccount = null;
      _index = _accountsOverviewTabIndex;
    });
  }

  void _openAccountForm(Account? account) {
    setState(() {
      _editingAccount = account;
      if (account == null) _accountFormNonce++;
      _accountFormReturnIndex =
          (_index == _accountsTabIndex || _index == _accountsOverviewTabIndex)
              ? _index
              : _accountsTabIndex;
      _index = _accountFormTabIndex;
    });
  }

  void _closeAccountForm() {
    setState(() {
      _editingAccount = null;
      _index = _accountFormReturnIndex;
    });

    // Alta, edición o incluso cancelación pueden haber cambiado la lista
    // de cuentas (una cuenta nueva ya trae su registro en
    // monthly_account_balances desde el alta, pero la foto en memoria de
    // MonthlyBalanceViewModel quedaría desactualizada si no la
    // refrescamos acá).
    widget.monthlyBalanceViewModel.checkCurrentMonth();
  }

  void _openCategoryForm(Category? category, {String initialType = 'expense'}) {
    setState(() {
      _editingCategory = category;
      _categoryInitialType = initialType;
      if (category == null) _categoryFormNonce++;
      _index = _categoryFormTabIndex;
    });
  }

  void _closeCategoryForm() {
    setState(() {
      _editingCategory = null;
      _index = _categoriesTabIndex;
    });
  }

  void _openMonthlyBalanceForm(List<Account> pendingAccounts) {
    setState(() {
      _pendingMonthlyBalanceAccounts = pendingAccounts;
      _monthlyBalanceNonce++;
      _index = _monthlyBalanceTabIndex;
    });
  }

  void _closeMonthlyBalanceForm() {
    setState(() {
      _pendingMonthlyBalanceAccounts = [];
      _index = 0; // Vuelve a "Inicio", único lugar desde donde se abre.
    });
  }

  void _openAddTransactionForm(String type) {
    setState(() {
      _transactionType = type;
      _addTransactionNonce++;
      _index = _addTransactionTabIndex;
    });
  }

  void _closeAddTransactionForm() {
    setState(() {
      _index = 0; // Vuelve a "Inicio", único lugar desde donde se abre.
    });
  }

  void _openServiceForm(Service? service) {
    setState(() {
      _editingService = service;
      if (service == null) _serviceFormNonce++;
      _index = _serviceFormTabIndex;
    });
  }

  void _closeServiceForm() {
    setState(() {
      _editingService = null;
      _index = _servicesTabIndex;
    });
  }

  void _openInvoiceForm() {
    setState(() {
      _invoiceFormNonce++;
      _index = _invoiceFormTabIndex;
    });
  }

  void _closeInvoiceForm() {
    setState(() {
      _index = _invoicesTabIndex;
    });
  }

  void _goToPendingInvoices() {
    setState(() {
      _invoicesNonce++;
      _invoicesInitialPendingFilter = true;
      _index = _invoicesTabIndex;
    });
  }

  /// Qué hacer cuando el usuario presiona "atrás" (botón físico/gesto en
  /// Android, botón atrás del navegador en Web) estando en una pestaña que
  /// no es "Inicio". En vez de dejar que el sistema cierre la app o
  /// navegue fuera de ella, volvemos a la pantalla lógica anterior,
  /// reutilizando las mismas funciones que ya usan los botones "cancelar"
  /// de cada formulario.
  void _handleBackNavigation() {
    switch (_index) {
      case _accountFormTabIndex:
        _closeAccountForm();
        break;
      case _categoryFormTabIndex:
        _closeCategoryForm();
        break;
      case _monthlyBalanceTabIndex:
        _closeMonthlyBalanceForm();
        break;
      case _addTransactionTabIndex:
        _closeAddTransactionForm();
        break;
      case _serviceFormTabIndex:
        _closeServiceForm();
        break;
      case _invoiceFormTabIndex:
        _closeInvoiceForm();
        break;
      case _transferFormTabIndex:
        _closeTransferForm();
        break;
      case _updateBalanceTabIndex:
        _closeUpdateBalance();
        break;
      default:
        // Pestañas de primer nivel (Movimientos, Estadísticas, Perfil) y
        // listados a los que solo se llega desde el drawer (Cuentas,
        // Categorías, Servicios, Facturas): "atrás" vuelve a Inicio.
        setState(() => _index = 0);
    }
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
        onSeeAllMovements: () => _onTabTap(1),
        onOpenMonthlyBalances: _openMonthlyBalanceForm,
        onOpenAddTransaction: _openAddTransactionForm,
        onGoToAccounts: () => _openAccountForm(null),
        onManageAccounts: _openAccountsOverview,
        onGoToInvoices: _goToPendingInvoices,
        onGoToTransfers: _openTransferForm,
      ),
      MovementsTab(
        transactionViewModel: widget.transactionViewModel,
        currency: widget.accountViewModel.primaryCurrency,
      ),
      StatisticsTab(
        transactionViewModel: widget.transactionViewModel,
        currency: widget.accountViewModel.primaryCurrency,
      ),
      ProfileScreen(viewModel: widget.authViewModel),
      AccountsTab(
        accountViewModel: widget.accountViewModel,
        onOpenForm: _openAccountForm,
      ),
      AccountFormTab(
        key: ValueKey(_editingAccount?.id ?? 'new-$_accountFormNonce'),
        userId: widget.authViewModel.userId ?? '',
        accountViewModel: widget.accountViewModel,
        account: _editingAccount,
        onDone: _closeAccountForm,
      ),
      CategoriesTab(
        categoryViewModel: widget.categoryViewModel,
        onEdit: (category) => _openCategoryForm(category),
      ),
      CategoryFormTab(
        key: ValueKey(_editingCategory?.id ?? 'new-$_categoryFormNonce'),
        userId: widget.authViewModel.userId ?? '',
        categoryViewModel: widget.categoryViewModel,
        category: _editingCategory,
        initialType: _categoryInitialType,
        onDone: _closeCategoryForm,
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
      ServicesTab(
        serviceViewModel: widget.serviceViewModel,
        categoryViewModel: widget.categoryViewModel,
        onEdit: (service) => _openServiceForm(service),
      ),
      ServiceFormTab(
        key: ValueKey(_editingService?.id ?? 'new-$_serviceFormNonce'),
        userId: widget.authViewModel.userId ?? '',
        serviceViewModel: widget.serviceViewModel,
        categoryViewModel: widget.categoryViewModel,
        service: _editingService,
        onDone: _closeServiceForm,
      ),
      InvoicesTab(
        key: ValueKey('invoices-$_invoicesNonce'),
        userId: widget.authViewModel.userId ?? '',
        invoiceViewModel: widget.invoiceViewModel,
        serviceViewModel: widget.serviceViewModel,
        categoryViewModel: widget.categoryViewModel,
        accountViewModel: widget.accountViewModel,
        initialPendingFilter: _invoicesInitialPendingFilter,
      ),
      InvoiceFormTab(
        key: ValueKey('invoice-form-$_invoiceFormNonce'),
        userId: widget.authViewModel.userId ?? '',
        invoiceViewModel: widget.invoiceViewModel,
        serviceViewModel: widget.serviceViewModel,
        onDone: _closeInvoiceForm,
      ),
      TransferFormTab(
        key: ValueKey('transfer-form-$_transferFormNonce'),
        userId: widget.authViewModel.userId,
        accountViewModel: widget.accountViewModel,
        transactionViewModel: widget.transactionViewModel,
        onDone: _closeTransferForm,
      ),
      AccountsOverviewTab(
        accountViewModel: widget.accountViewModel,
        onOpenForm: _openAccountForm,
        onOpenUpdateBalance: _openUpdateBalance,
      ),
      UpdateBalanceTab(
        key: ValueKey('update-balance-${_updatingBalanceAccount?.id}'),
        account: _updatingBalanceAccount,
        onDone: _closeUpdateBalance,
      ),
    ];

    return PopScope(
      // Solo dejamos que el sistema haga "pop" real (cerrar la app en
      // Android, navegar atrás en el browser) cuando estamos en "Inicio".
      // En cualquier otra pestaña, lo interceptamos y resolvemos nosotros
      // a qué pantalla lógica volver.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        drawer: _AppDrawer(
          currentIndex: _index,
          onSelect: _onTabTap,
          userId: widget.authViewModel.userId,
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.authBackgroundTop,
                AppColors.authBackgroundBottom,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                LumaHeader(trailing: _headerAction()),
                Expanded(child: IndexedStack(index: _index, children: tabs)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _index,
          onTap: _onTabTap,
        ),
      ),
    );
  }

  /// Acción a la derecha del header, según la pestaña activa.
  Widget? _headerAction() {
    switch (_index) {
      case 0:
      case _accountsOverviewTabIndex:
        return const IconButton(
          onPressed: null,
          icon: Icon(Icons.notifications_none_rounded),
          color: AppColors.authTextPrimary,
        );
      case 3:
        return const IconButton(
          onPressed: null,
          icon: Icon(Icons.settings_outlined),
          color: AppColors.authTextPrimary,
        );
      case _accountsTabIndex:
        return IconButton(
          onPressed: () => _openAccountForm(null),
          icon: const Icon(Icons.add_rounded),
          color: AppColors.authTextPrimary,
        );
      case _categoriesTabIndex:
        return IconButton(
          onPressed: () => _openCategoryForm(null),
          icon: const Icon(Icons.add_rounded),
          color: AppColors.authTextPrimary,
        );
      case _servicesTabIndex:
        return IconButton(
          onPressed: () => _openServiceForm(null),
          icon: const Icon(Icons.add_rounded),
          color: AppColors.authTextPrimary,
        );
      case _invoicesTabIndex:
        return IconButton(
          onPressed: _openInvoiceForm,
          icon: const Icon(Icons.add_rounded),
          color: AppColors.authTextPrimary,
        );
      default:
        return null;
    }
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.authBackgroundBottom,
        border: Border(top: BorderSide(color: AppColors.authCardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isSelected = i == currentIndex;
              final color =
                  isSelected ? AppColors.authAccent : AppColors.authTextFooter;

              return InkWell(
                onTap: () => onTap(i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1, color: color, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        item.$2,
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: 16,
                        height: 2,
                        child: isSelected
                            ? const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.authAccent,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final String? userId;

  const _AppDrawer({
    required this.currentIndex,
    required this.onSelect,
    required this.userId,
  });

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    final color =
        isSelected ? AppColors.authAccent : AppColors.authTextSecondary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.authCardFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAccountsSection = currentIndex == _accountsTabIndex ||
        currentIndex == _accountFormTabIndex ||
        currentIndex == _accountsOverviewTabIndex ||
        currentIndex == _updateBalanceTabIndex;
    final isCategoriesSection = currentIndex == _categoriesTabIndex ||
        currentIndex == _categoryFormTabIndex;
    final isServicesSection = currentIndex == _servicesTabIndex ||
        currentIndex == _serviceFormTabIndex;
    final isInvoicesSection = currentIndex == _invoicesTabIndex ||
        currentIndex == _invoiceFormTabIndex;

    void selectTab(int index) {
      Navigator.of(context).pop();
      onSelect(index);
    }

    return Drawer(
      backgroundColor: AppColors.authBackgroundBottom,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  LumaLogo(size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Luma',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.authCardBorder),
            const SizedBox(height: 8),
            // Inicio
            _tile(
              context,
              icon: _navItems[0].$1,
              label: _navItems[0].$2,
              isSelected: currentIndex == 0,
              onTap: () => selectTab(0),
            ),
            // Cuentas
            _tile(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cuentas',
              isSelected: isAccountsSection,
              onTap: userId == null ? null : () => selectTab(_accountsTabIndex),
            ),
            // Categorías
            _tile(
              context,
              icon: Icons.sell_outlined,
              label: 'Categorías',
              isSelected: isCategoriesSection,
              onTap:
                  userId == null ? null : () => selectTab(_categoriesTabIndex),
            ),
            // Servicios
            _tile(
              context,
              icon: Icons.receipt_long_outlined,
              label: 'Servicios',
              isSelected: isServicesSection,
              onTap: userId == null ? null : () => selectTab(_servicesTabIndex),
            ),
            // Facturas
            _tile(
              context,
              icon: Icons.request_page_outlined,
              label: 'Facturas',
              isSelected: isInvoicesSection,
              onTap: userId == null ? null : () => selectTab(_invoicesTabIndex),
            ),
            // Movimientos, Estadísticas, Perfil
            ...List.generate(_navItems.length - 1, (i) {
              final index = i + 1;
              final item = _navItems[index];
              return _tile(
                context,
                icon: item.$1,
                label: item.$2,
                isSelected: currentIndex == index,
                onTap: () => selectTab(index),
              );
            }),
          ],
        ),
      ),
    );
  }
}
