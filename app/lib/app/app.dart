import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/accounts/data/repositories/account_repository.dart';
import '../features/accounts/data/services/account_service.dart';
import '../features/accounts/presentation/view_models/account_view_model.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/data/services/auth_service.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/categories/data/repositories/category_repository.dart';
import '../features/categories/data/services/category_service.dart';
import '../features/categories/presentation/view_models/category_view_model.dart';
import '../features/invoices/data/repositories/invoice_repository.dart';
import '../features/invoices/data/services/invoice_service.dart';
import '../features/invoices/presentation/view_models/invoice_view_model.dart';
import '../features/monthly_balances/data/repositories/monthly_balance_repository.dart';
import '../features/monthly_balances/data/services/monthly_balance_service.dart';
import '../features/monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../features/preferences/data/repositories/preferences_repository.dart';
import '../features/preferences/presentation/view_models/preferences_view_model.dart';
import '../features/services/data/repositories/service_repository.dart';
import '../features/services/data/services/service_service.dart';
import '../features/services/presentation/view_models/service_view_model.dart';
import '../features/transactions/data/repositories/transaction_repository.dart';
import '../features/transactions/data/services/transaction_service.dart';
import '../features/transactions/presentation/view_models/transaction_view_model.dart';
import 'router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class LumaApp extends StatefulWidget {
  /// Mensaje de la Edge Function `check-app-version` cuando el estado es
  /// "outdated_but_usable": hay una versión nueva, pero la instalada
  /// todavía se puede seguir usando. Si no es `null`, se muestra un
  /// diálogo informativo al abrir la app (ver [_showUpdateAvailableDialog]).
  final String? pendingUpdateMessage;

  const LumaApp({super.key, this.pendingUpdateMessage});

  @override
  State<LumaApp> createState() => _LumaAppState();
}

class _LumaAppState extends State<LumaApp> {
  late final AuthViewModel _authViewModel;
  late final AccountViewModel _accountViewModel;
  late final TransactionViewModel _transactionViewModel;
  late final CategoryViewModel _categoryViewModel;
  late final MonthlyBalanceViewModel _monthlyBalanceViewModel;
  late final ServiceViewModel _serviceViewModel;
  late final InvoiceViewModel _invoiceViewModel;
  late final PreferencesViewModel _preferencesViewModel;
  late final _router = buildAppRouter(
    authViewModel: _authViewModel,
    accountViewModel: _accountViewModel,
    transactionViewModel: _transactionViewModel,
    categoryViewModel: _categoryViewModel,
    monthlyBalanceViewModel: _monthlyBalanceViewModel,
    serviceViewModel: _serviceViewModel,
    invoiceViewModel: _invoiceViewModel,
    preferencesViewModel: _preferencesViewModel,
  );

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;

    final authRepository = AuthRepository(AuthService(client));
    _authViewModel = AuthViewModel(authRepository);

    final accountRepository = AccountRepository(AccountService(client));
    _accountViewModel = AccountViewModel(accountRepository);

    final transactionRepository =
        TransactionRepository(TransactionService(client));
    _transactionViewModel = TransactionViewModel(transactionRepository);

    final categoryRepository = CategoryRepository(CategoryService(client));
    _categoryViewModel = CategoryViewModel(categoryRepository);

    final monthlyBalanceRepository =
        MonthlyBalanceRepository(MonthlyBalanceService(client));
    _monthlyBalanceViewModel =
        MonthlyBalanceViewModel(monthlyBalanceRepository);

    final serviceRepository = ServiceRepository(ServiceService(client));
    _serviceViewModel = ServiceViewModel(serviceRepository);

    final invoiceRepository = InvoiceRepository(InvoiceService(client));
    _invoiceViewModel =
        InvoiceViewModel(invoiceRepository, _transactionViewModel);

    // A diferencia del resto de los view models, no depende de Supabase ni
    // de haber iniciado sesión (son preferencias del dispositivo, no del
    // usuario logueado) — se carga siempre, no dentro de _loadUserData().
    _preferencesViewModel = PreferencesViewModel(PreferencesRepository());
    _preferencesViewModel.loadPreferences();

    _authViewModel.addListener(_onAuthChanged);
    if (_authViewModel.isAuthenticated) {
      _loadUserData();
    }

    final pendingMessage = widget.pendingUpdateMessage;
    if (pendingMessage != null) {
      // Se espera al primer frame para poder mostrar el diálogo con el
      // Navigator del router ya montado (ver `_router.routerDelegate`).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateAvailableDialog(pendingMessage);
      });
    }
  }

  void _onAuthChanged() {
    if (_authViewModel.isAuthenticated) {
      _loadUserData();
    }
  }

  void _loadUserData() {
    _accountViewModel.loadAccounts();
    _transactionViewModel.loadCurrentMonth();
    _categoryViewModel.loadCategories();
    _monthlyBalanceViewModel.checkCurrentMonth();
    _serviceViewModel.loadServices();
    _invoiceViewModel.loadInvoices();
  }

  // Diálogo de "hay una versión nueva, pero podés seguir usando esta"
  // (estado "outdated_but_usable" de `check-app-version`). A propósito no
  // tiene ningún botón de acción: se cierra tocando afuera (o "atrás"), y
  // el usuario sigue directo a la app.
  void _showUpdateAvailableDialog(String message) {
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        icon: const Icon(
          Icons.system_update_rounded,
          color: AppColors.authAccent,
        ),
        title: const Text(
          'Hay una actualización disponible',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.authTextSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthChanged);
    _authViewModel.dispose();
    _accountViewModel.dispose();
    _transactionViewModel.dispose();
    _categoryViewModel.dispose();
    _monthlyBalanceViewModel.dispose();
    _serviceViewModel.dispose();
    _invoiceViewModel.dispose();
    _preferencesViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Luma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
