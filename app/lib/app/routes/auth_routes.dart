import 'package:go_router/go_router.dart';

import '../../core/navigation/app_back.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/preferences_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/home/presentation/screens/routed_screen_scaffold.dart';
import '../app_dependencies.dart';

/// Login screen. It lives outside the app shell (no bottom nav).
GoRoute loginRoute(AppDependencies deps) {
  final authViewModel = deps.authViewModel;

  return GoRoute(
    path: '/login',
    builder: (context, state) => LoginScreen(viewModel: authViewModel),
  );
}

/// Profile and preferences routes, inside the app shell. Preferences sit under
/// `/profile/` so the bottom nav keeps highlighting "Profile".
List<RouteBase> profileRoutes(AppDependencies deps) {
  final authViewModel = deps.authViewModel;
  final preferencesViewModel = deps.preferencesViewModel;
  final appLockViewModel = deps.appLockViewModel;

  return [
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
  ];
}
