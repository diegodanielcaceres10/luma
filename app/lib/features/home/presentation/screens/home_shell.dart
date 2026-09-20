import 'package:flutter/material.dart';

import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/screens/account_form_tab.dart';
import '../../../accounts/presentation/screens/accounts_overview_tab.dart';
import '../../../accounts/presentation/screens/accounts_tab.dart';
import '../../../accounts/presentation/screens/update_balance_tab.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
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
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../../transfers/presentation/screens/transfer_form_tab.dart';
import '../../../../app/theme/app_colors.dart';
import 'dashboard_tab.dart';

/// FASE 2 de la migración a rutas (go_router): "Inicio", "Movimientos",
/// "Estadísticas" y "Perfil" ya son ramas propias de un
/// `StatefulShellRoute.indexedStack` (ver router.dart y
/// app_shell_screen.dart, que pone el Scaffold/drawer/header/bottomNav
/// compartido). Lo que queda ACÁ es todo lo que todavía no tiene ruta
/// propia: el Dashboard y las pantallas a las que solo se llega desde el
/// drawer o desde el propio Dashboard (Cuentas, Categorías, Servicios,
/// Facturas y sus formularios) — siguen viviendo colgadas de la rama
/// "Inicio" con el mismo mecanismo de índice + IndexedStack de antes.
/// Migrarlas a rutas propias es una fase aparte del plan.
///
/// El índice 0 es siempre el Dashboard.
const _accountsTabIndex = 1;
const _accountFormTabIndex = 2;
const _categoriesTabIndex = 3;
const _categoryFormTabIndex = 4;
const _monthlyBalanceTabIndex = 5;
const _addTransactionTabIndex = 6;
const _servicesTabIndex = 7;
const _serviceFormTabIndex = 8;
const _invoicesTabIndex = 9;
const _invoiceFormTabIndex = 10;
const _transferFormTabIndex = 11;
const _accountsOverviewTabIndex = 12;
const _updateBalanceTabIndex = 13;

class HomeBranchScreen extends StatefulWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final ServiceViewModel serviceViewModel;
  final InvoiceViewModel invoiceViewModel;

  /// AppShellScreen (el Scaffold compartido) necesita reconstruirse cada
  /// vez que cambia el índice interno de acá — de eso depende qué acción
  /// muestra el header, qué ítem del drawer queda resaltado, y si el
  /// botón atrás debe cerrar la app o resolverse acá adentro.
  final VoidCallback onChanged;

  /// "Movimientos" ahora es su propia rama del bottom nav — este
  /// callback reemplaza lo que antes hacía `_onTabTap(1)` para el botón
  /// "ver todos" del Dashboard.
  final VoidCallback onGoToMovements;

  const HomeBranchScreen({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.monthlyBalanceViewModel,
    required this.serviceViewModel,
    required this.invoiceViewModel,
    required this.onChanged,
    required this.onGoToMovements,
  });

  @override
  State<HomeBranchScreen> createState() => HomeBranchScreenState();
}

class HomeBranchScreenState extends State<HomeBranchScreen> {
  int _index = 0;

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

  /// Todo cambio de índice (o de cualquier estado que afecte al header,
  /// al drawer o al botón atrás) pasa por acá para que AppShellScreen se
  /// entere y se reconstruya.
  void _update(VoidCallback fn) {
    setState(fn);
    widget.onChanged();
  }

  // ---- API pública para AppShellScreen (el Scaffold compartido) ----

  /// Índice interno actual.
  int get index => _index;

  /// true solo en el Dashboard — es cuándo AppShellScreen puede dejar que
  /// el sistema haga "pop" real (cerrar la app / navegar atrás en Web).
  bool get isDashboard => _index == 0;

  bool get isAccountsSection =>
      _index == _accountsTabIndex ||
      _index == _accountFormTabIndex ||
      _index == _accountsOverviewTabIndex ||
      _index == _updateBalanceTabIndex;

  bool get isCategoriesSection =>
      _index == _categoriesTabIndex || _index == _categoryFormTabIndex;

  bool get isServicesSection =>
      _index == _servicesTabIndex || _index == _serviceFormTabIndex;

  bool get isInvoicesSection =>
      _index == _invoicesTabIndex || _index == _invoiceFormTabIndex;

  /// Acción a mostrar en el header para el índice actual.
  Widget? get headerAction => _headerAction();

  /// Vuelve al Dashboard. Lo usa AppShellScreen tanto cuando se toca
  /// "Inicio" en el bottom nav/drawer (siempre resetea, sin importar en
  /// qué pantalla interna se haya quedado) como al volver acá desde otra
  /// rama con el botón atrás.
  void goToDashboard() => _update(() => _index = 0);

  void goToAccounts() => _update(() => _index = _accountsTabIndex);
  void goToCategories() => _update(() => _index = _categoriesTabIndex);
  void goToServices() => _update(() => _index = _servicesTabIndex);
  void goToInvoices() => _update(() => _index = _invoicesTabIndex);

  /// Qué hacer cuando el usuario presiona "atrás" (botón físico/gesto en
  /// Android, botón atrás del navegador en Web) estando en esta rama. Si
  /// ya estamos en el Dashboard no hay nada que resolver acá —
  /// AppShellScreen se encarga de qué pasa después.
  void handleBackPress() {
    if (_index != 0) _handleBackNavigation();
  }

  // ---- El resto es exactamente la misma lógica que tenía HomeShell ----

  void _openTransferForm() {
    _update(() {
      _transferFormNonce++;
      _index = _transferFormTabIndex;
    });
  }

  void _closeTransferForm() {
    _update(() {
      _index = 0; // Vuelve a "Inicio" (Dashboard), único lugar desde donde se abre.
    });
  }

  // Vista general de "Cuentas" (prototipo), a la que se llega desde el
  // ícono de gerenciamiento en la BalanceCard del Dashboard. Al no tener
  // formulario propio, "atrás" vuelve a "Inicio" por el caso default de
  // _handleBackNavigation.
  void _openAccountsOverview() {
    _update(() => _index = _accountsOverviewTabIndex);
  }

  // Pantalla "Actualizar saldo", a la que se llega desde el ícono de
  // sincronización de cada tarjeta en AccountsOverviewTab. Siempre vuelve
  // a esa vista, único lugar desde donde se abre.
  void _openUpdateBalance(Account account) {
    _update(() {
      _updatingBalanceAccount = account;
      _index = _updateBalanceTabIndex;
    });
  }

  void _closeUpdateBalance() {
    _update(() {
      _updatingBalanceAccount = null;
      _index = _accountsOverviewTabIndex;
    });
  }

  void _openAccountForm(Account? account) {
    _update(() {
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
    _update(() {
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
    _update(() {
      _editingCategory = category;
      _categoryInitialType = initialType;
      if (category == null) _categoryFormNonce++;
      _index = _categoryFormTabIndex;
    });
  }

  void _closeCategoryForm() {
    _update(() {
      _editingCategory = null;
      _index = _categoriesTabIndex;
    });
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
      _index = 0; // Vuelve a "Inicio" (Dashboard), único lugar desde donde se abre.
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
    _update(() {
      _index = 0; // Vuelve a "Inicio" (Dashboard), único lugar desde donde se abre.
    });
  }

  void _openServiceForm(Service? service) {
    _update(() {
      _editingService = service;
      if (service == null) _serviceFormNonce++;
      _index = _serviceFormTabIndex;
    });
  }

  void _closeServiceForm() {
    _update(() {
      _editingService = null;
      _index = _servicesTabIndex;
    });
  }

  void _openInvoiceForm() {
    _update(() {
      _invoiceFormNonce++;
      _index = _invoiceFormTabIndex;
    });
  }

  void _closeInvoiceForm() {
    _update(() {
      _index = _invoicesTabIndex;
    });
  }

  void _goToPendingInvoices() {
    _update(() {
      _invoicesNonce++;
      _invoicesInitialPendingFilter = true;
      _index = _invoicesTabIndex;
    });
  }

  /// Mismo criterio que tenía HomeShell: reutiliza las funciones "cerrar"
  /// de cada formulario para volver a la pantalla lógica anterior.
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
        // Listados a los que solo se llega desde el drawer (Cuentas,
        // Categorías, Servicios, Facturas) y la vista general de cuentas:
        // "atrás" vuelve al Dashboard.
        _update(() => _index = 0);
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
        onSeeAllMovements: widget.onGoToMovements,
        onOpenMonthlyBalances: _openMonthlyBalanceForm,
        onOpenAddTransaction: _openAddTransactionForm,
        onGoToAccounts: () => _openAccountForm(null),
        onManageAccounts: _openAccountsOverview,
        onGoToInvoices: _goToPendingInvoices,
        onGoToTransfers: _openTransferForm,
      ),
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
        accountViewModel: widget.accountViewModel,
        categoryViewModel: widget.categoryViewModel,
        transactionViewModel: widget.transactionViewModel,
        userId: widget.authViewModel.userId,
        onDone: _closeUpdateBalance,
      ),
    ];

    return IndexedStack(index: _index, children: tabs);
  }

  /// Acción a la derecha del header, según la pantalla interna activa.
  Widget? _headerAction() {
    switch (_index) {
      case 0:
      case _accountsOverviewTabIndex:
        return const IconButton(
          onPressed: null,
          icon: Icon(Icons.notifications_none_rounded),
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
