import 'package:flutter/widgets.dart' show BuildContext, Widget, Listenable;
import 'package:go_router/go_router.dart';

import '../core/navigation/app_back.dart';
import '../core/navigation/entity_route_guard.dart';
import '../features/accounts/data/models/account.dart';
import '../features/accounts/presentation/screens/account_form_screen.dart';
import '../features/accounts/presentation/screens/account_update_balance_screen.dart';
import '../features/accounts/presentation/screens/account_view_screen.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/accounts/presentation/view_models/account_view_model.dart';
import '../features/app_lock/presentation/screens/lock_screen.dart';
import '../features/app_lock/presentation/view_models/app_lock_view_model.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/categories/data/models/category.dart';
import '../features/categories/presentation/screens/categories_screen.dart';
import '../features/categories/presentation/screens/category_form_screen.dart';
import '../features/categories/presentation/screens/category_view_screen.dart';
import '../features/categories/presentation/view_models/category_view_model.dart';
import '../features/home/presentation/screens/app_shell_screen.dart';
import '../features/home/presentation/screens/home_shell.dart';
import '../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../features/invoices/data/models/invoice.dart';
import '../features/invoices/presentation/screens/invoice_form_screen.dart';
import '../features/invoices/presentation/screens/invoice_view_screen.dart';
import '../features/invoices/presentation/screens/invoices_screen.dart';
import '../features/invoices/presentation/view_models/invoice_view_model.dart';
import '../features/monthly_balances/presentation/screens/monthly_balance_tab.dart';
import '../features/monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../features/preferences/presentation/screens/preferences_screen.dart';
import '../features/preferences/presentation/view_models/preferences_view_model.dart';
import '../features/services/data/models/service.dart';
import '../features/services/presentation/screens/service_form_screen.dart';
import '../features/services/presentation/screens/service_view_screen.dart';
import '../features/services/presentation/screens/services_screen.dart';
import '../features/services/presentation/view_models/service_view_model.dart';
import '../features/transactions/presentation/screens/add_transaction_tab.dart';
import '../features/transactions/presentation/screens/movements_tab.dart';
import '../features/transactions/presentation/screens/statistics_tab.dart';
import '../features/transactions/presentation/view_models/transaction_view_model.dart';
import '../features/transfers/presentation/screens/transfer_form_tab.dart';
import 'not_found_screen.dart';

/// Guards de las rutas con `:id` (ver [EntityRouteGuard]): si el id no
/// existe mandan a la lista con un aviso, en vez de abrir el formulario como
/// si fuera un alta.
Widget _accountGuard(
  AccountViewModel vm,
  String? id,
  Widget Function(BuildContext, Account) builder,
) =>
    EntityRouteGuard<Account>(
      listenable: vm,
      entityId: id,
      find: (id) {
        for (final a in vm.accounts) {
          if (a.id == id) return a;
        }
        return null;
      },
      isLoading: () => vm.isLoading,
      hasLoaded: () => vm.hasLoaded,
      errorMessage: () => vm.errorMessage,
      notFoundMessage: 'No encontramos esa cuenta.',
      fallbackRoute: '/accounts',
      builder: builder,
    );

Widget _categoryGuard(
  CategoryViewModel vm,
  String? id,
  Widget Function(BuildContext, Category) builder,
) =>
    EntityRouteGuard<Category>(
      listenable: vm,
      entityId: id,
      find: (id) {
        for (final c in vm.categories) {
          if (c.id == id) return c;
        }
        return null;
      },
      isLoading: () => vm.isLoading,
      hasLoaded: () => vm.hasLoaded,
      errorMessage: () => vm.errorMessage,
      notFoundMessage: 'No encontramos esa categoría.',
      fallbackRoute: '/categories',
      builder: builder,
    );

Widget _serviceGuard(
  ServiceViewModel vm,
  String? id,
  Widget Function(BuildContext, Service) builder,
) =>
    EntityRouteGuard<Service>(
      listenable: vm,
      entityId: id,
      find: (id) {
        for (final s in vm.services) {
          if (s.id == id) return s;
        }
        return null;
      },
      isLoading: () => vm.isLoading,
      hasLoaded: () => vm.hasLoaded,
      errorMessage: () => vm.errorMessage,
      notFoundMessage: 'No encontramos ese servicio.',
      fallbackRoute: '/services',
      builder: builder,
    );

Widget _invoiceGuard(
  InvoiceViewModel vm,
  String? id,
  Widget Function(BuildContext, Invoice) builder,
) =>
    EntityRouteGuard<Invoice>(
      listenable: vm,
      entityId: id,
      find: (id) {
        for (final i in vm.invoices) {
          if (i.id == id) return i;
        }
        return null;
      },
      isLoading: () => vm.isLoading,
      hasLoaded: () => vm.hasLoaded,
      errorMessage: () => vm.errorMessage,
      notFoundMessage: 'No encontramos esa factura.',
      fallbackRoute: '/invoices',
      builder: builder,
    );

/// Navegación con historial único: el shell (drawer, header y bottom nav)
/// es un `ShellRoute` común — un solo Navigator y una sola pila para toda
/// la app — así que cada pantalla que se abre (por el drawer, el bottom
/// nav o un botón) se apila con `context.push`, y "atrás" (botón del
/// navegador o del dispositivo) vuelve siempre a la pantalla anterior, en
/// el mismo orden en que se visitaron.
///
/// Todas las pantallas son rutas hermanas, al mismo nivel: no hay rutas
/// anidadas. Todas conservan el bottom nav visible porque el shell queda
/// por fuera del Navigator.
///
/// Todo botón "volver"/"cancelar" y "guardar" (al terminar) hace
/// `context.goBack()` (ver core/navigation/app_back.dart): se comporta
/// exactamente igual que el "atrás" del navegador o del dispositivo — en
/// Web dispara `history.back()`, así que no agrega entradas nuevas al
/// historial — y si no hay historial dentro de la app (ej. se entró
/// directo por URL) manda al Dashboard.
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
  required PreferencesViewModel preferencesViewModel,
  required AppLockViewModel appLockViewModel,
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
    // de armar uno nuevo. Se le suma AppLockViewModel para que el
    // `redirect` también se reevalúe cuando la app se bloquea/desbloquea.
    refreshListenable: Listenable.merge([authViewModel, appLockViewModel]),
    redirect: (context, state) {
      final isAuthenticated = authViewModel.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/';

      // Gate de bloqueo local (biometría), independiente del login — ver
      // AppLockViewModel. Solo puede estar `true` si ya hay sesión, así
      // que este chequeo va después de los dos de arriba.
      final isLocked = appLockViewModel.isLocked;
      final isLocking = state.matchedLocation == '/lock';
      if (isAuthenticated && isLocked && !isLocking) return '/lock';
      if (isAuthenticated && !isLocked && isLocking) return '/';

      return null;
    },
    // URLs que no coinciden con ninguna ruta. El `redirect` de arriba corre
    // ANTES que esto, también para rutas que no existen: sin sesión,
    // cualquier URL inválida termina en '/login', así que esta pantalla
    // solo la ve quien ya está autenticado. Va por fuera del shell (sin
    // header ni bottom nav).
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.path),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(viewModel: authViewModel),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => LockScreen(
          viewModel: appLockViewModel,
          authViewModel: authViewModel,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShellScreen(child: child),
        routes: [
          // Inicio (Dashboard)
          GoRoute(
            path: '/',
            builder: (context, state) => HomeBranchScreen(
              authViewModel: authViewModel,
              accountViewModel: accountViewModel,
              transactionViewModel: transactionViewModel,
              categoryViewModel: categoryViewModel,
              monthlyBalanceViewModel: monthlyBalanceViewModel,
              invoiceViewModel: invoiceViewModel,
              serviceViewModel: serviceViewModel,
            ),
          ),
          // ---- Saldo inicial del mes ----
          GoRoute(
            path: '/monthly-balance',
            builder: (context, state) => RoutedScreenScaffold(
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
                onDone: () => context.goBack(),
              ),
            ),
          ),
          // ---- Nueva transacción ----
          GoRoute(
            // El regex restringe `:type` a income/expense: cualquier otro
            // valor no coincide con ninguna ruta y cae en NotFoundScreen
            // (ver `errorBuilder`). go_router compara los paths sin
            // distinguir mayúsculas, por eso el builder lo normaliza.
            path: '/add-transaction/:type(income|expense)',
            builder: (context, state) {
              final type = state.pathParameters['type']!.toLowerCase();
              return RoutedScreenScaffold(
                body: AddTransactionTab(
                  type: type,
                  userId: authViewModel.userId ?? '',
                  accountViewModel: accountViewModel,
                  categoryViewModel: categoryViewModel,
                  transactionViewModel: transactionViewModel,
                  onDone: () => context.goBack(),
                ),
              );
            },
          ),
          // ---- Transferencia entre cuentas ----
          GoRoute(
            path: '/transfer',
            builder: (context, state) => RoutedScreenScaffold(
              body: TransferFormTab(
                userId: authViewModel.userId,
                accountViewModel: accountViewModel,
                transactionViewModel: transactionViewModel,
                onDone: () => context.goBack(),
              ),
            ),
          ),
          // ---- Cuentas ----
          // '/accounts' (pestaña del drawer) y '/accounts-overview' (push
          // desde el Dashboard) muestran la misma pantalla
          // (AccountsScreen) — solo cambia si se pasa onBack, ver su
          // doc. Repetir el widget en dos rutas en vez de una es a
          // propósito: '/accounts' es una pestaña de primer nivel del
          // shell (navegación por tab, no por push), así que necesita su
          // propia ruta aunque construya la misma pantalla.
          GoRoute(
            path: '/accounts',
            builder: (context, state) => RoutedScreenScaffold(
              body: AccountsScreen(
                accountViewModel: accountViewModel,
                onOpenView: (account) =>
                    context.push('/accounts/${account.id}'),
                onOpenForm: () => context.push('/accounts/new'),
              ),
            ),
          ),
          GoRoute(
            path: '/accounts/new',
            builder: (context, state) => RoutedScreenScaffold(
              body: AccountFormScreen(
                userId: authViewModel.userId ?? '',
                accountViewModel: accountViewModel,
                onDone: () {
                  monthlyBalanceViewModel.checkCurrentMonth();
                  context.goBack();
                },
              ),
            ),
          ),
          GoRoute(
            path: '/accounts/:id',
            // Declarada después de '/accounts/new': go_router prueba las
            // rutas en el orden en que están acá, así que '/accounts/new'
            // gana esa URL exacta antes de que ':id' la capture como
            // "new" — mismo motivo por el que no hace falta cuidar el
            // orden contra '/accounts/:id/edit' y '/accounts/:id/balance'
            // (tienen un segmento más, no compiten por la misma URL).
            builder: (context, state) => RoutedScreenScaffold(
              body: _accountGuard(
                accountViewModel,
                state.pathParameters['id'],
                (context, account) => AccountViewScreen(
                  account: account,
                  accountViewModel: accountViewModel,
                  onEdit: () => context.push('/accounts/${account.id}/edit'),
                  onUpdateBalance: () =>
                      context.push('/accounts/${account.id}/balance'),
                  onBack: () => context.goBack(),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/accounts/:id/edit',
            // Si el :id no existe, el guard manda a '/accounts' con un
            // aviso (en vez de abrir el formulario como alta).
            builder: (context, state) => RoutedScreenScaffold(
              body: _accountGuard(
                accountViewModel,
                state.pathParameters['id'],
                (context, account) => AccountFormScreen(
                  userId: authViewModel.userId ?? '',
                  accountViewModel: accountViewModel,
                  account: account,
                  onDone: () {
                    monthlyBalanceViewModel.checkCurrentMonth();
                    context.goBack();
                  },
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/accounts/:id/balance',
            builder: (context, state) => RoutedScreenScaffold(
              body: _accountGuard(
                accountViewModel,
                state.pathParameters['id'],
                (context, account) => AccountUpdateBalanceScreen(
                  account: account,
                  accountViewModel: accountViewModel,
                  categoryViewModel: categoryViewModel,
                  serviceViewModel: serviceViewModel,
                  invoiceViewModel: invoiceViewModel,
                  transactionViewModel: transactionViewModel,
                  userId: authViewModel.userId,
                  onDone: () => context.goBack(),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/accounts-overview',
            builder: (context, state) => RoutedScreenScaffold(
              body: AccountsScreen(
                accountViewModel: accountViewModel,
                onBack: () => context.goBack(),
                onOpenView: (account) =>
                    context.push('/accounts/${account.id}'),
                onOpenForm: () => context.push('/accounts/new'),
              ),
            ),
          ),
          // ---- Categorías ----
          GoRoute(
            path: '/categories',
            builder: (context, state) => RoutedScreenScaffold(
              body: CategoriesScreen(
                categoryViewModel: categoryViewModel,
                onOpenView: (category) =>
                    context.push('/categories/${category.id}'),
                onOpenForm: () => context.push('/categories/new'),
              ),
            ),
          ),
          GoRoute(
            path: '/categories/new',
            builder: (context, state) => RoutedScreenScaffold(
              body: CategoryFormScreen(
                userId: authViewModel.userId ?? '',
                categoryViewModel: categoryViewModel,
                onDone: () => context.goBack(),
              ),
            ),
          ),
          GoRoute(
            path: '/categories/:id',
            // Declared after '/categories/new' so that exact URL wins over
            // ':id'.
            builder: (context, state) => RoutedScreenScaffold(
              body: _categoryGuard(
                categoryViewModel,
                state.pathParameters['id'],
                (context, category) => CategoryViewScreen(
                  category: category,
                  categoryViewModel: categoryViewModel,
                  currency: accountViewModel.primaryCurrency,
                  onEdit: () =>
                      context.push('/categories/${category.id}/edit'),
                  onBack: () => context.goBack(),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/categories/:id/edit',
            builder: (context, state) => RoutedScreenScaffold(
              body: _categoryGuard(
                categoryViewModel,
                state.pathParameters['id'],
                (context, category) => CategoryFormScreen(
                  userId: authViewModel.userId ?? '',
                  categoryViewModel: categoryViewModel,
                  category: category,
                  onDone: () => context.goBack(),
                ),
              ),
            ),
          ),
          // ---- Servicios ----
          GoRoute(
            path: '/services',
            builder: (context, state) => RoutedScreenScaffold(
              body: ServicesScreen(
                serviceViewModel: serviceViewModel,
                categoryViewModel: categoryViewModel,
                currency: accountViewModel.primaryCurrency,
                onOpenView: (service) =>
                    context.push('/services/${service.id}'),
                onOpenForm: () => context.push('/services/new'),
              ),
            ),
          ),
          GoRoute(
            path: '/services/new',
            builder: (context, state) => RoutedScreenScaffold(
              body: ServiceFormScreen(
                userId: authViewModel.userId ?? '',
                serviceViewModel: serviceViewModel,
                categoryViewModel: categoryViewModel,
                onDone: () => context.goBack(),
              ),
            ),
          ),
          GoRoute(
            path: '/services/:id',
            // Declared after '/services/new' so that exact URL wins over
            // ':id'.
            builder: (context, state) => RoutedScreenScaffold(
              body: _serviceGuard(
                serviceViewModel,
                state.pathParameters['id'],
                (context, service) => ServiceViewScreen(
                  service: service,
                  serviceViewModel: serviceViewModel,
                  categoryViewModel: categoryViewModel,
                  currency: accountViewModel.primaryCurrency,
                  onEdit: () => context.push('/services/${service.id}/edit'),
                  onBack: () => context.goBack(),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/services/:id/edit',
            builder: (context, state) => RoutedScreenScaffold(
              body: _serviceGuard(
                serviceViewModel,
                state.pathParameters['id'],
                (context, service) => ServiceFormScreen(
                  userId: authViewModel.userId ?? '',
                  serviceViewModel: serviceViewModel,
                  categoryViewModel: categoryViewModel,
                  service: service,
                  onDone: () => context.goBack(),
                ),
              ),
            ),
          ),
          // ---- Facturas ----
          GoRoute(
            path: '/invoices',
            // Sin transición: cambiar de filtro hace push (para que
            // "atrás" vuelva al filtro anterior — ver InvoicesScreen), pero
            // sigue siendo la misma pantalla, así que no debe animar
            // como si fuera una pantalla nueva.
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: RoutedScreenScaffold(
                body: InvoicesScreen(
                  invoiceViewModel: invoiceViewModel,
                  serviceViewModel: serviceViewModel,
                  currency: accountViewModel.primaryCurrency,
                  onOpenView: (invoice) =>
                      context.push('/invoices/${invoice.id}'),
                  onOpenForm: () => context.push('/invoices/new'),
                  // Cada push crea un InvoicesScreen nuevo, así que alcanza
                  // con leer el query param una vez, al construir.
                  initialFilter: state.uri.queryParameters['filter'],
                  initialMonth: state.uri.queryParameters['month'],
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/invoices/new',
            builder: (context, state) => RoutedScreenScaffold(
              body: InvoiceFormScreen(
                userId: authViewModel.userId ?? '',
                invoiceViewModel: invoiceViewModel,
                serviceViewModel: serviceViewModel,
                onDone: () => context.goBack(),
              ),
            ),
          ),
          GoRoute(
            path: '/invoices/:id',
            // Declared after '/invoices/new' so that exact URL wins over
            // ':id'.
            builder: (context, state) => RoutedScreenScaffold(
              body: _invoiceGuard(
                invoiceViewModel,
                state.pathParameters['id'],
                (context, invoice) => InvoiceViewScreen(
                  userId: authViewModel.userId ?? '',
                  invoice: invoice,
                  invoiceViewModel: invoiceViewModel,
                  serviceViewModel: serviceViewModel,
                  categoryViewModel: categoryViewModel,
                  accountViewModel: accountViewModel,
                  currency: accountViewModel.primaryCurrency,
                  onEdit: () => context.push('/invoices/${invoice.id}/edit'),
                  onBack: () => context.goBack(),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/invoices/:id/edit',
            // Si el :id no existe, el guard manda a '/invoices' con un
            // aviso (en vez de abrir el formulario como alta).
            builder: (context, state) => RoutedScreenScaffold(
              body: _invoiceGuard(
                invoiceViewModel,
                state.pathParameters['id'],
                (context, invoice) => InvoiceFormScreen(
                  userId: authViewModel.userId ?? '',
                  invoiceViewModel: invoiceViewModel,
                  serviceViewModel: serviceViewModel,
                  invoice: invoice,
                  onDone: () => context.goBack(),
                ),
              ),
            ),
          ),
          // Movimientos
          GoRoute(
            path: '/movements',
            // Sin transición: cambiar de filtro hace push (para que
            // "atrás" vuelva a la combinación anterior — ver
            // MovementsTab), pero sigue siendo la misma pantalla.
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: MovementsTab(
                userId: authViewModel.userId ?? '',
                transactionViewModel: transactionViewModel,
                accountViewModel: accountViewModel,
                categoryViewModel: categoryViewModel,
                currency: accountViewModel.primaryCurrency,
                initialType: state.uri.queryParameters['type'],
                initialRange: state.uri.queryParameters['range'],
                initialCategory: state.uri.queryParameters['category'],
                initialAccount: state.uri.queryParameters['account'],
                initialMonth: state.uri.queryParameters['month'],
              ),
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
            builder: (context, state) => ProfileScreen(
              viewModel: authViewModel,
              onOpenPreferences: () => context.push('/profile/preferences'),
            ),
          ),
          // Bajo '/profile/' (no '/preferences' suelto) para que el bottom
          // nav siga resaltando "Perfil" mientras se navega acá — ver
          // AppShellScreen._navIndexFor.
          GoRoute(
            path: '/profile/preferences',
            builder: (context, state) => RoutedScreenScaffold(
              body: PreferencesScreen(
                viewModel: preferencesViewModel,
                appLockViewModel: appLockViewModel,
                onBack: () => context.goBack(),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
