import 'package:go_router/go_router.dart';

import '../features/accounts/data/models/account.dart';
import '../features/accounts/presentation/screens/account_form_tab.dart';
import '../features/accounts/presentation/screens/accounts_overview_tab.dart';
import '../features/accounts/presentation/screens/accounts_tab.dart';
import '../features/accounts/presentation/screens/update_balance_tab.dart';
import '../features/accounts/presentation/view_models/account_view_model.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/categories/data/models/category.dart';
import '../features/categories/presentation/screens/categories_tab.dart';
import '../features/categories/presentation/screens/category_form_tab.dart';
import '../features/categories/presentation/view_models/category_view_model.dart';
import '../features/home/presentation/screens/app_shell_screen.dart';
import '../features/home/presentation/screens/home_shell.dart';
import '../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../features/invoices/presentation/screens/invoice_form_tab.dart';
import '../features/invoices/presentation/screens/invoices_tab.dart';
import '../features/invoices/presentation/view_models/invoice_view_model.dart';
import '../features/monthly_balances/presentation/screens/monthly_balance_tab.dart';
import '../features/monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../features/services/data/models/service.dart';
import '../features/services/presentation/screens/service_form_tab.dart';
import '../features/services/presentation/screens/services_tab.dart';
import '../features/services/presentation/view_models/service_view_model.dart';
import '../features/transactions/presentation/screens/add_transaction_tab.dart';
import '../features/transactions/presentation/screens/movements_tab.dart';
import '../features/transactions/presentation/screens/statistics_tab.dart';
import '../features/transactions/presentation/view_models/transaction_view_model.dart';
import '../features/transfers/presentation/screens/transfer_form_tab.dart';

Account? _findAccount(AccountViewModel vm, String? id) {
  for (final a in vm.accounts) {
    if (a.id == id) return a;
  }
  return null;
}

Category? _findCategory(CategoryViewModel vm, String? id) {
  for (final c in vm.categories) {
    if (c.id == id) return c;
  }
  return null;
}

Service? _findService(ServiceViewModel vm, String? id) {
  for (final s in vm.services) {
    if (s.id == id) return s;
  }
  return null;
}

/// Navegación con historial único: el shell (drawer, header y bottom nav)
/// es un `ShellRoute` común — un solo Navigator y una sola pila para toda
/// la app — así que cada pantalla que se abre (por el drawer, el bottom
/// nav o un botón) se apila con `context.push`, y "atrás" (botón del
/// navegador o del dispositivo) vuelve siempre a la pantalla anterior, en
/// el mismo orden en que se visitaron.
///
/// Inicio, Movimientos, Estadísticas y Perfil son las 4 entradas del
/// bottom nav; Cuentas, Categorías, Servicios y Facturas (con sus
/// formularios, la vista general de cuentas y "actualizar saldo"), saldo
/// inicial del mes, nueva transacción y transferencia cuelgan de la ruta
/// '/' — así, si se abre una URL directa (ej. al recargar el navegador en
/// '/accounts/new'), la pila arranca con el Dashboard abajo y "atrás" /
/// `context.pop()` siguen funcionando. Todas conservan el bottom nav
/// visible porque el shell queda por fuera del Navigator.
///
/// Todo botón "volver"/"cancelar" y "guardar" (al terminar) hace
/// `context.pop()`, así que siempre vuelve exactamente a la pantalla que
/// lo abrió, sin importar desde dónde se haya llegado (ej. el formulario
/// de cuenta se abre tanto desde "Cuentas" como desde la vista general).
///
/// La ruta '/' es, directamente, el Dashboard — ver [HomeBranchScreen].
GoRouter buildAppRouter({
  required AuthViewModel authViewModel,
  required AccountViewModel accountViewModel,
  required TransactionViewModel transactionViewModel,
  required CategoryViewModel categoryViewModel,
  required MonthlyBalanceViewModel monthlyBalanceViewModel,
  required ServiceViewModel serviceViewModel,
  required InvoiceViewModel invoiceViewModel,
}) {
  // Por defecto, go_router SOLO refleja `context.go()` en la barra de
  // direcciones del navegador — un `context.push()` cambia de pantalla
  // pero deja la URL vieja (es diseño de la librería, no un bug nuestro:
  // pensado para casos tipo diálogo, donde no tendría sentido que la URL
  // apunte ahí). Como acá SÍ queremos que cada pantalla empujada tenga su
  // URL propia (Cuentas > Nueva cuenta, Saldos iniciales, etc.), hay que
  // prender esta opción global antes de crear el GoRouter.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    initialLocation: '/',
    // GoRouter no re-evalúa `redirect` solo porque cambió el estado de la
    // app — hay que decirle explícitamente cuándo hacerlo.
    // AuthViewModel ya notifica en cada cambio de sesión (ver
    // `_onAuthStateChange`), así que reusamos ese mismo Listenable en vez
    // de armar uno nuevo.
    refreshListenable: authViewModel,
    redirect: (context, state) {
      final isAuthenticated = authViewModel.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(viewModel: authViewModel),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShellScreen(
          authViewModel: authViewModel,
          child: child,
        ),
        routes: [
          // Inicio (Dashboard) + Cuentas/Categorías/Servicios/Facturas y
          // sus formularios, saldo inicial, nueva transacción y
          // transferencia, anidadas para que una URL directa arme la pila
          // con el Dashboard debajo.
          GoRoute(
            path: '/',
            builder: (context, state) => HomeBranchScreen(
              authViewModel: authViewModel,
              accountViewModel: accountViewModel,
              transactionViewModel: transactionViewModel,
              categoryViewModel: categoryViewModel,
              monthlyBalanceViewModel: monthlyBalanceViewModel,
              invoiceViewModel: invoiceViewModel,
            ),
            routes: [
              // ---- Saldo inicial del mes ----
              GoRoute(
                path: 'monthly-balance',
                builder: (context, state) => RoutedScreenScaffold(
                  title: 'Saldos iniciales',
                  showAppBar: false,
                  body: MonthlyBalanceTab(
                    userId: authViewModel.userId ?? '',
                    // Se recalcula acá mismo en vez de viajar por la
                    // navegación — misma cuenta que usaba el
                    // Dashboard (ver dashboard_tab.dart).
                    pendingAccounts: monthlyBalanceViewModel.checked
                        ? monthlyBalanceViewModel.pendingAccounts(
                            accountViewModel.activeAccounts)
                        : const [],
                    monthlyBalanceViewModel: monthlyBalanceViewModel,
                    onDone: () => context.pop(),
                  ),
                ),
              ),
              // ---- Nueva transacción ----
              GoRoute(
                path: 'add-transaction/:type',
                builder: (context, state) {
                  final type = state.pathParameters['type'] == 'income'
                      ? 'income'
                      : 'expense';
                  return RoutedScreenScaffold(
                    title: type == 'income'
                        ? 'Añadir ingreso'
                        : 'Añadir gasto',
                    showAppBar: false,
                    body: AddTransactionTab(
                      type: type,
                      userId: authViewModel.userId ?? '',
                      accountViewModel: accountViewModel,
                      categoryViewModel: categoryViewModel,
                      transactionViewModel: transactionViewModel,
                      onDone: () => context.pop(),
                    ),
                  );
                },
              ),
              // ---- Transferencia entre cuentas ----
              GoRoute(
                path: 'transfer',
                builder: (context, state) => RoutedScreenScaffold(
                  title: 'Transferencia entre cuentas',
                  showAppBar: false,
                  body: TransferFormTab(
                    userId: authViewModel.userId,
                    accountViewModel: accountViewModel,
                    transactionViewModel: transactionViewModel,
                    onDone: () => context.pop(),
                  ),
                ),
              ),
              // ---- Cuentas ----
              GoRoute(
                path: 'accounts',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: AccountsTab(
                    accountViewModel: accountViewModel,
                    onAdd: () => context.push('/accounts/new'),
                    onOpenForm: (account) => account == null
                        ? context.push('/accounts/new')
                        : context.push('/accounts/${account.id}/edit'),
                  ),
                ),
              ),
              GoRoute(
                path: 'accounts/new',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: AccountFormTab(
                    userId: authViewModel.userId ?? '',
                    accountViewModel: accountViewModel,
                    onDone: () {
                      monthlyBalanceViewModel.checkCurrentMonth();
                      context.pop();
                    },
                  ),
                ),
              ),
              GoRoute(
                path: 'accounts/:id/edit',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: AccountFormTab(
                    userId: authViewModel.userId ?? '',
                    accountViewModel: accountViewModel,
                    account: _findAccount(
                        accountViewModel, state.pathParameters['id']),
                    onDone: () {
                      monthlyBalanceViewModel.checkCurrentMonth();
                      context.pop();
                    },
                  ),
                ),
              ),
              GoRoute(
                path: 'accounts/:id/balance',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: UpdateBalanceTab(
                    account: _findAccount(
                        accountViewModel, state.pathParameters['id']),
                    accountViewModel: accountViewModel,
                    categoryViewModel: categoryViewModel,
                    transactionViewModel: transactionViewModel,
                    userId: authViewModel.userId,
                    onDone: () => context.pop(),
                  ),
                ),
              ),
              GoRoute(
                path: 'accounts-overview',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: AccountsOverviewTab(
                    accountViewModel: accountViewModel,
                    onBack: () => context.pop(),
                    onOpenForm: (account) => account == null
                        ? context.push('/accounts/new')
                        : context.push('/accounts/${account.id}/edit'),
                    onOpenUpdateBalance: (account) =>
                        context.push('/accounts/${account.id}/balance'),
                  ),
                ),
              ),
              // ---- Categorías ----
              GoRoute(
                path: 'categories',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: CategoriesTab(
                    categoryViewModel: categoryViewModel,
                    onAdd: () => context.push('/categories/new'),
                    onEdit: (category) =>
                        context.push('/categories/${category.id}/edit'),
                  ),
                ),
              ),
              GoRoute(
                path: 'categories/new',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: CategoryFormTab(
                    userId: authViewModel.userId ?? '',
                    categoryViewModel: categoryViewModel,
                    onDone: () => context.pop(),
                  ),
                ),
              ),
              GoRoute(
                path: 'categories/:id/edit',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: CategoryFormTab(
                    userId: authViewModel.userId ?? '',
                    categoryViewModel: categoryViewModel,
                    category: _findCategory(
                        categoryViewModel, state.pathParameters['id']),
                    onDone: () => context.pop(),
                  ),
                ),
              ),
              // ---- Servicios ----
              GoRoute(
                path: 'services',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: ServicesTab(
                    serviceViewModel: serviceViewModel,
                    categoryViewModel: categoryViewModel,
                    onAdd: () => context.push('/services/new'),
                    onEdit: (service) =>
                        context.push('/services/${service.id}/edit'),
                  ),
                ),
              ),
              GoRoute(
                path: 'services/new',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: ServiceFormTab(
                    userId: authViewModel.userId ?? '',
                    serviceViewModel: serviceViewModel,
                    categoryViewModel: categoryViewModel,
                    onDone: () => context.pop(),
                  ),
                ),
              ),
              GoRoute(
                path: 'services/:id/edit',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: ServiceFormTab(
                    userId: authViewModel.userId ?? '',
                    serviceViewModel: serviceViewModel,
                    categoryViewModel: categoryViewModel,
                    service: _findService(
                        serviceViewModel, state.pathParameters['id']),
                    onDone: () => context.pop(),
                  ),
                ),
              ),
              // ---- Facturas ----
              GoRoute(
                path: 'invoices',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: InvoicesTab(
                    userId: authViewModel.userId ?? '',
                    invoiceViewModel: invoiceViewModel,
                    serviceViewModel: serviceViewModel,
                    categoryViewModel: categoryViewModel,
                    accountViewModel: accountViewModel,
                    onAdd: () => context.push('/invoices/new'),
                    // Cada push crea un InvoicesTab nuevo (ya no hace
                    // falta el nonce que usaba HomeShell) — alcanza
                    // con leer el query param una vez, al construir.
                    initialPendingFilter:
                        state.uri.queryParameters['pending'] == 'true',
                  ),
                ),
              ),
              GoRoute(
                path: 'invoices/new',
                builder: (context, state) => RoutedScreenScaffold(
                  title: '',
                  showAppBar: false,
                  body: InvoiceFormTab(
                    userId: authViewModel.userId ?? '',
                    invoiceViewModel: invoiceViewModel,
                    serviceViewModel: serviceViewModel,
                    onDone: () => context.pop(),
                  ),
                ),
              ),
            ],
          ),
          // Movimientos
          GoRoute(
            path: '/movements',
            builder: (context, state) => MovementsTab(
              transactionViewModel: transactionViewModel,
              currency: accountViewModel.primaryCurrency,
            ),
          ),
          // Estadísticas
          GoRoute(
            path: '/statistics',
            builder: (context, state) => StatisticsTab(
              transactionViewModel: transactionViewModel,
              categoryViewModel: categoryViewModel,
              currency: accountViewModel.primaryCurrency,
            ),
          ),
          // Perfil
          GoRoute(
            path: '/profile',
            builder: (context, state) =>
                ProfileScreen(viewModel: authViewModel),
          ),
        ],
      ),
    ],
  );
}
