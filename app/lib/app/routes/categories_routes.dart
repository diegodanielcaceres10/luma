import 'package:flutter/widgets.dart' show BuildContext, Widget;
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_back.dart';
import '../../core/navigation/entity_route_guard.dart';
import '../../features/categories/data/models/category.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/categories/presentation/screens/category_form_screen.dart';
import '../../features/categories/presentation/screens/category_view_screen.dart';
import '../../features/categories/presentation/view_models/category_view_model.dart';
import '../../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../app_dependencies.dart';

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

/// Routes of the categories feature, inside the app shell.
List<RouteBase> categoriesRoutes(AppDependencies deps) {
  final authViewModel = deps.authViewModel;
  final accountViewModel = deps.accountViewModel;
  final transactionViewModel = deps.transactionViewModel;
  final categoryViewModel = deps.categoryViewModel;

  return [
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
            transactionViewModel: transactionViewModel,
            currency: accountViewModel.primaryCurrency,
            onEdit: () => context.push('/categories/${category.id}/edit'),
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
  ];
}
