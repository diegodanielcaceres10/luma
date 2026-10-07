import 'package:go_router/go_router.dart';

import '../features/accounts/presentation/view_models/account_view_model.dart';
import '../features/accounts/presentation/view_models/monthly_balance_view_model.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/auth/presentation/view_models/preferences_view_model.dart';
import '../features/categories/presentation/view_models/category_view_model.dart';
import '../features/home/presentation/screens/app_shell_screen.dart';
import '../features/home/presentation/view_models/app_lock_view_model.dart';
import '../features/invoices/presentation/view_models/invoice_view_model.dart';
import '../features/services/presentation/view_models/service_view_model.dart';
import '../features/transactions/presentation/view_models/transaction_view_model.dart';
import 'app_dependencies.dart';
import 'not_found_screen.dart';
import 'routes/accounts_routes.dart';
import 'routes/auth_routes.dart';
import 'routes/categories_routes.dart';
import 'routes/home_routes.dart';
import 'routes/invoices_routes.dart';
import 'routes/services_routes.dart';
import 'routes/transactions_routes.dart';

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

  final deps = AppDependencies(
    authViewModel: authViewModel,
    accountViewModel: accountViewModel,
    transactionViewModel: transactionViewModel,
    categoryViewModel: categoryViewModel,
    monthlyBalanceViewModel: monthlyBalanceViewModel,
    serviceViewModel: serviceViewModel,
    invoiceViewModel: invoiceViewModel,
    preferencesViewModel: preferencesViewModel,
    appLockViewModel: appLockViewModel,
  );

  return GoRouter(
    initialLocation: '/',
    // Re-evaluate `redirect` when the session changes. The biometric lock is
    // not a route: see AppLockGate in app.dart.
    refreshListenable: authViewModel,
    redirect: (context, state) {
      final isAuthenticated = authViewModel.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/';

      return null;
    },
    // Unknown URLs. `redirect` runs first, so unauthenticated users land on
    // '/login' and never see this; it sits outside the shell.
    errorBuilder: (context, state) => NotFoundScreen(location: state.uri.path),
    routes: [
      loginRoute(deps),
      ShellRoute(
        builder: (context, state, child) => AppShellScreen(child: child),
        routes: [
          ...homeRoutes(deps),
          ...transactionsRoutes(deps),
          ...accountsRoutes(deps),
          ...categoriesRoutes(deps),
          ...servicesRoutes(deps),
          ...invoicesRoutes(deps),
          ...profileRoutes(deps),
        ],
      ),
    ],
  );
}
