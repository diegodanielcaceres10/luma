import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_shell.dart';
import '../app_dependencies.dart';

/// Dashboard route (`/`), inside the app shell.
List<RouteBase> homeRoutes(AppDependencies deps) {
  final authViewModel = deps.authViewModel;
  final accountViewModel = deps.accountViewModel;
  final transactionViewModel = deps.transactionViewModel;
  final categoryViewModel = deps.categoryViewModel;
  final monthlyBalanceViewModel = deps.monthlyBalanceViewModel;
  final serviceViewModel = deps.serviceViewModel;
  final invoiceViewModel = deps.invoiceViewModel;

  return [
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
  ];
}
