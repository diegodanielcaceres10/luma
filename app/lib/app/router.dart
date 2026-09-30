import 'package:flutter/widgets.dart' show BuildContext, Widget, Listenable;
import 'package:go_router/go_router.dart';

import '../core/navigation/app_back.dart';
import '../core/navigation/entity_route_guard.dart';
import '../features/accounts/data/models/account.dart';
import '../features/accounts/presentation/screens/account_form_screen.dart';
import '../features/accounts/presentation/screens/account_justify_uncontrolled_screen.dart';
import '../features/accounts/presentation/screens/account_monthly_balance_screen.dart';
import '../features/accounts/presentation/screens/account_update_balance_screen.dart';
import '../features/accounts/presentation/screens/account_view_screen.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/accounts/presentation/view_models/account_view_model.dart';
import '../features/accounts/presentation/view_models/monthly_balance_view_model.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/preferences_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/auth/presentation/view_models/preferences_view_model.dart';
import '../features/categories/data/models/category.dart';
import '../features/categories/presentation/screens/categories_screen.dart';
import '../features/categories/presentation/screens/category_form_screen.dart';
import '../features/categories/presentation/screens/category_view_screen.dart';
import '../features/categories/presentation/view_models/category_view_model.dart';
import '../features/home/presentation/screens/app_shell_screen.dart';
import '../features/home/presentation/screens/home_shell.dart';
import '../features/home/presentation/screens/lock_screen.dart';
import '../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../features/home/presentation/view_models/app_lock_view_model.dart';
import '../features/invoices/data/models/invoice.dart';
import '../features/invoices/presentation/screens/invoice_form_screen.dart';
import '../features/invoices/presentation/screens/invoice_view_screen.dart';
import '../features/invoices/presentation/screens/invoices_screen.dart';
import '../features/invoices/presentation/view_models/invoice_view_model.dart';
import '../features/services/data/models/service.dart';
import '../features/services/presentation/screens/service_form_screen.dart';
import '../features/services/presentation/screens/service_view_screen.dart';
import '../features/services/presentation/screens/services_screen.dart';
import '../features/services/presentation/view_models/service_view_model.dart';
import '../features/transactions/presentation/screens/statistics_screen.dart';
import '../features/transactions/presentation/screens/transaction_form_screen.dart';
import '../features/transactions/presentation/screens/transaction_form_transfer_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';
import '../features/transactions/presentation/view_models/transaction_view_model.dart';
import 'not_found_screen.dart';

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

/// Single-history navigation: every screen is a sibling route under one
/// `ShellRoute` and is opened with `context.push`, so back (browser or
/// device) always returns to the previous screen and the bottom nav stays
/// visible.
///
/// Back/cancel/save buttons call `context.goBack()` (see
/// core/navigation/app_back.dart). '/' is the Dashboard ([HomeBranchScreen]).
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
  // By default go_router only reflects `context.go()` in the browser URL;
  // enable this so pushed screens get their own URL too.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    initialLocation: '/',
    // Re-evaluate `redirect` when the session or the app lock changes.
    refreshListenable: Listenable.merge([authViewModel, appLockViewModel]),
    redirect: (context, state) {
      final isAuthenticated = authViewModel.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/';

      // Local biometric lock gate; only reachable with a session, so it runs
      // after the auth checks.
      final isLocked = appLockViewModel.isLocked;
      final isLocking = state.matchedLocation == '/lock';
      if (isAuthenticated && isLocked && !isLocking) return '/lock';
      if (isAuthenticated && !isLocked && isLocking) return '/';

      return null;
    },
    // Unknown URLs. `redirect` runs first, so unauthenticated users land on
    // '/login' and never see this; it sits outside the shell.
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
          GoRoute(
            path: '/monthly-balance',
            builder: (context, state) => RoutedScreenScaffold(
              body: AccountMonthlyBalanceScreen(
                userId: authViewModel.userId ?? '',
                pendingAccounts: monthlyBalanceViewModel.checked
                    ? monthlyBalanceViewModel.pendingAccounts(
                        accountViewModel.activeAccounts)
                    : const [],
                monthlyBalanceViewModel: monthlyBalanceViewModel,
                onDone: () => context.goBack(),
              ),
            ),
          ),
          GoRoute(
            // The regex limits `:type` to income/expense; the builder
            // lowercases it because go_router matches paths case-insensitively.
            path: '/add-transaction/:type(income|expense)',
            builder: (context, state) {
              final type = state.pathParameters['type']!.toLowerCase();
              return RoutedScreenScaffold(
                body: TransactionFormScreen(
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
          GoRoute(
            path: '/transfer',
            builder: (context, state) => RoutedScreenScaffold(
              body: TransactionFormTransferScreen(
                userId: authViewModel.userId,
                accountViewModel: accountViewModel,
                transactionViewModel: transactionViewModel,
                onDone: () => context.goBack(),
              ),
            ),
          ),
          // '/accounts' is a top-level shell tab and '/accounts-overview' is
          // pushed from the Dashboard; both build AccountsScreen.
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
            // Declared after '/accounts/new' so that exact URL wins over ':id'.
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
                  onJustifyUncontrolled: () =>
                      context.push('/accounts/${account.id}/justify'),
                  onBack: () => context.goBack(),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/accounts/:id/edit',
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
            path: '/accounts/:id/justify',
            builder: (context, state) => RoutedScreenScaffold(
              body: _accountGuard(
                accountViewModel,
                state.pathParameters['id'],
                (context, account) => AccountJustifyUncontrolledScreen(
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
          GoRoute(
            path: '/invoices',
            // No transition: changing the filter pushes the same screen, so it
            // must not animate as a new one.
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
                  // Each push builds a new InvoicesScreen, so reading the query
                  // param once is enough.
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
          GoRoute(
            path: '/movements',
            // No transition: same screen, filter changes are pushes.
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: TransactionsScreen(
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
          GoRoute(
            path: '/statistics',
            builder: (context, state) => StatisticsScreen(
              transactionViewModel: transactionViewModel,
              categoryViewModel: categoryViewModel,
              currency: accountViewModel.primaryCurrency,
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => ProfileScreen(
              viewModel: authViewModel,
              onOpenPreferences: () => context.push('/profile/preferences'),
            ),
          ),
          // Under '/profile/' so the bottom nav keeps highlighting "Profile".
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
