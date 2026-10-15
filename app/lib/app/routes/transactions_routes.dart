import 'package:go_router/go_router.dart';

import '../../core/navigation/app_back.dart';
import '../../features/accounts/presentation/screens/account_justify_month_screen.dart';
import '../../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../../features/transactions/presentation/screens/transaction_form_screen.dart';
import '../../features/transactions/presentation/screens/transaction_form_transfer_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/screens/transactions_statistics_screen.dart';
import '../../features/transactions/presentation/view_models/transactions_filters.dart';
import '../app_dependencies.dart';

/// Routes of the transactions feature: new movement and transfer forms, the
/// movements history and the statistics, inside the app shell.
List<RouteBase> transactionsRoutes(AppDependencies deps) {
  final authViewModel = deps.authViewModel;
  final accountViewModel = deps.accountViewModel;
  final transactionViewModel = deps.transactionViewModel;
  final categoryViewModel = deps.categoryViewModel;
  final monthlyBalanceViewModel = deps.monthlyBalanceViewModel;
  final serviceViewModel = deps.serviceViewModel;
  final invoiceViewModel = deps.invoiceViewModel;

  return [
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
            monthlyBalanceViewModel: monthlyBalanceViewModel,
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
          monthlyBalanceViewModel: monthlyBalanceViewModel,
          onDone: () => context.goBack(),
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
      builder: (context, state) => TransactionsStatisticsScreen(
        transactionViewModel: transactionViewModel,
        categoryViewModel: categoryViewModel,
        accountViewModel: accountViewModel,
        monthlyBalanceViewModel: monthlyBalanceViewModel,
        currency: accountViewModel.primaryCurrency,
        onJustifyMonth: (month) => context.push(
          '/statistics/justify-month'
          '?month=${TransactionsFilters.monthQueryValue(month) ?? ''}',
        ),
      ),
    ),
    GoRoute(
      path: '/statistics/justify-month',
      builder: (context, state) => RoutedScreenScaffold(
        body: AccountJustifyMonthScreen(
          month: TransactionsFilters.monthFromQuery(
            state.uri.queryParameters['month'],
          ),
          userId: authViewModel.userId ?? '',
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
  ];
}
