import 'package:flutter/widgets.dart' show BuildContext, Widget;
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_back.dart';
import '../../core/navigation/entity_route_guard.dart';
import '../../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../../features/services/data/models/service.dart';
import '../../features/services/presentation/screens/service_form_screen.dart';
import '../../features/services/presentation/screens/service_view_screen.dart';
import '../../features/services/presentation/screens/services_screen.dart';
import '../../features/services/presentation/view_models/service_view_model.dart';
import '../app_dependencies.dart';

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

/// Routes of the services feature, inside the app shell.
List<RouteBase> servicesRoutes(AppDependencies deps) {
  final authViewModel = deps.authViewModel;
  final accountViewModel = deps.accountViewModel;
  final categoryViewModel = deps.categoryViewModel;
  final serviceViewModel = deps.serviceViewModel;
  final invoiceViewModel = deps.invoiceViewModel;
  final preferencesViewModel = deps.preferencesViewModel;

  return [
    GoRoute(
      path: '/services',
      builder: (context, state) => RoutedScreenScaffold(
        body: ServicesScreen(
          serviceViewModel: serviceViewModel,
          categoryViewModel: categoryViewModel,
          preferencesViewModel: preferencesViewModel,
          currency: accountViewModel.primaryCurrency,
          onOpenView: (service) =>
              context.push('/services/${service.id}'),
          onOpenForm: () => context.push('/services/new'),
          onOpenPreferences: () => context.push('/profile/preferences'),
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
            invoiceViewModel: invoiceViewModel,
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
  ];
}
