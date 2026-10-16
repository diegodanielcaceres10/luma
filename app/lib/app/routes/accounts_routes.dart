import 'package:flutter/widgets.dart' show BuildContext, Widget;
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_back.dart';
import '../../core/navigation/entity_route_guard.dart';
import '../../features/accounts/data/models/account.dart';
import '../../features/accounts/presentation/screens/account_form_screen.dart';
import '../../features/accounts/presentation/screens/account_justify_uncontrolled_screen.dart';
import '../../features/accounts/presentation/screens/account_monthly_balance_screen.dart';
import '../../features/accounts/presentation/screens/account_update_balance_screen.dart';
import '../../features/accounts/presentation/screens/account_view_screen.dart';
import '../../features/accounts/presentation/screens/accounts_screen.dart';
import '../../features/accounts/presentation/view_models/account_view_model.dart';
import '../../features/accounts/presentation/widgets/opening_balance_gate.dart';
import '../../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../app_dependencies.dart';

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

/// Routes of the accounts feature, inside the app shell. Order matters:
/// `/accounts/new` must stay before `/accounts/:id`.
List<RouteBase> accountsRoutes(AppDependencies deps) {
  final authViewModel = deps.authViewModel;
  final accountViewModel = deps.accountViewModel;
  final transactionViewModel = deps.transactionViewModel;
  final categoryViewModel = deps.categoryViewModel;
  final monthlyBalanceViewModel = deps.monthlyBalanceViewModel;
  final serviceViewModel = deps.serviceViewModel;
  final invoiceViewModel = deps.invoiceViewModel;
  final preferencesViewModel = deps.preferencesViewModel;

  return [
    // '/accounts' is a top-level shell tab and '/accounts-overview' is
    // pushed from the Dashboard; both build AccountsScreen.
    GoRoute(
      path: '/accounts',
      builder: (context, state) => RoutedScreenScaffold(
        body: AccountsScreen(
          accountViewModel: accountViewModel,
          preferencesViewModel: preferencesViewModel,
          onOpenView: (account) =>
              context.push('/accounts/${account.id}'),
          onOpenForm: () => context.push('/accounts/new'),
          onOpenPreferences: () => context.push('/profile/preferences'),
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
          (context, account) => OpeningBalanceGate(
            monthlyBalanceViewModel: monthlyBalanceViewModel,
            account: account,
            onCompleteBalance: () =>
                context.push('/accounts/${account.id}/monthly-balance'),
            onBack: () => context.goBack(),
            child: AccountUpdateBalanceScreen(
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
    ),
    GoRoute(
      path: '/accounts/:id/monthly-balance',
      builder: (context, state) => RoutedScreenScaffold(
        body: _accountGuard(
          accountViewModel,
          state.pathParameters['id'],
          (context, account) => AccountMonthlyBalanceScreen(
            userId: authViewModel.userId ?? '',
            account: account,
            accountViewModel: accountViewModel,
            categoryViewModel: categoryViewModel,
            serviceViewModel: serviceViewModel,
            invoiceViewModel: invoiceViewModel,
            transactionViewModel: transactionViewModel,
            monthlyBalanceViewModel: monthlyBalanceViewModel,
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
          (context, account) => OpeningBalanceGate(
            monthlyBalanceViewModel: monthlyBalanceViewModel,
            account: account,
            onCompleteBalance: () =>
                context.push('/accounts/${account.id}/monthly-balance'),
            onBack: () => context.goBack(),
            child: AccountJustifyUncontrolledScreen(
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
    ),
    GoRoute(
      path: '/accounts-overview',
      builder: (context, state) => RoutedScreenScaffold(
        body: AccountsScreen(
          accountViewModel: accountViewModel,
          preferencesViewModel: preferencesViewModel,
          onBack: () => context.goBack(),
          onOpenView: (account) =>
              context.push('/accounts/${account.id}'),
          onOpenForm: () => context.push('/accounts/new'),
          onOpenPreferences: () => context.push('/profile/preferences'),
        ),
      ),
    ),
  ];
}
