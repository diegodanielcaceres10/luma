import 'package:flutter/widgets.dart' show BuildContext, Widget;
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_back.dart';
import '../../core/navigation/entity_route_guard.dart';
import '../../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../../features/invoices/data/models/invoice.dart';
import '../../features/invoices/presentation/screens/invoice_form_screen.dart';
import '../../features/invoices/presentation/screens/invoice_view_screen.dart';
import '../../features/invoices/presentation/screens/invoices_screen.dart';
import '../../features/invoices/presentation/view_models/invoice_view_model.dart';
import '../app_dependencies.dart';

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

/// Routes of the invoices feature, inside the app shell.
List<RouteBase> invoicesRoutes(AppDependencies deps) {
  final authViewModel = deps.authViewModel;
  final accountViewModel = deps.accountViewModel;
  final categoryViewModel = deps.categoryViewModel;
  final monthlyBalanceViewModel = deps.monthlyBalanceViewModel;
  final serviceViewModel = deps.serviceViewModel;
  final invoiceViewModel = deps.invoiceViewModel;
  final preferencesViewModel = deps.preferencesViewModel;

  return [
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
            preferencesViewModel: preferencesViewModel,
            currency: accountViewModel.primaryCurrency,
            onOpenView: (invoice) =>
                context.push('/invoices/${invoice.id}'),
            onOpenForm: () => context.push('/invoices/new'),
            onOpenPreferences: () => context.push('/profile/preferences'),
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
            monthlyBalanceViewModel: monthlyBalanceViewModel,
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
  ];
}
