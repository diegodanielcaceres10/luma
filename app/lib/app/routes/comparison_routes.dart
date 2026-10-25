import 'package:go_router/go_router.dart';

import '../../core/navigation/app_back.dart';
import '../../features/comparison/presentation/screens/month_comparison_screen.dart';
import '../../features/comparison/presentation/view_models/comparison_months.dart';
import '../../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../app_dependencies.dart';

/// Route of the month comparison, opened from the statistics screen.
List<RouteBase> comparisonRoutes(AppDependencies deps) {
  return [
    GoRoute(
      path: '/statistics/compare',
      builder: (context, state) {
        // The URL only sets the months the screen opens with.
        final months = ComparisonMonths.fromQuery(
          from: state.uri.queryParameters['from'],
          to: state.uri.queryParameters['to'],
        );
        return RoutedScreenScaffold(
          body: MonthComparisonScreen(
            comparisonViewModel: deps.comparisonViewModel,
            categoryViewModel: deps.categoryViewModel,
            serviceViewModel: deps.serviceViewModel,
            invoiceViewModel: deps.invoiceViewModel,
            initialBefore: months.before,
            initialAfter: months.after,
            currency: deps.accountViewModel.primaryCurrency,
            onDone: () => context.goBack(),
          ),
        );
      },
    ),
  ];
}
