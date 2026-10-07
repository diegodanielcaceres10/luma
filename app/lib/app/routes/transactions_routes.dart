import 'package:go_router/go_router.dart';

import '../../core/navigation/app_back.dart';
import '../../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../../features/transactions/presentation/screens/transaction_form_screen.dart';
import '../../features/transactions/presentation/screens/transaction_form_transfer_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/screens/transactions_statistics_screen.dart';
import '../app_dependencies.dart';

/// Routes of the transactions feature: new movement and transfer forms, the
/// movements history and the statistics, inside the app shell.
List<RouteBase> transactionsRoutes(AppDependencies deps) {
  final authViewModel = deps.authViewModel;
  final accountViewModel = deps.accountViewModel;
  final transactionViewModel = deps.transactionViewModel;
  final categoryViewModel = deps.categoryViewModel;
  final monthlyBalanceViewModel = deps.monthlyBalanceViewModel;

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
        currency: accountViewModel.primaryCurrency,
      ),
    ),
  ];
}
