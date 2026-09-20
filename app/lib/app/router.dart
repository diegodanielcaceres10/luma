import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/presentation/view_models/account_view_model.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/categories/presentation/view_models/category_view_model.dart';
import '../features/home/presentation/screens/app_shell_screen.dart';
import '../features/home/presentation/screens/home_shell.dart';
import '../features/invoices/presentation/view_models/invoice_view_model.dart';
import '../features/monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../features/services/presentation/view_models/service_view_model.dart';
import '../features/transactions/presentation/screens/movements_tab.dart';
import '../features/transactions/presentation/screens/statistics_tab.dart';
import '../features/transactions/presentation/view_models/transaction_view_model.dart';

/// FASE 2 de la migración de la navegación por tabs a rutas (plan
/// acordado con el usuario): las 4 pestañas reales del bottom nav
/// (Inicio, Movimientos, Estadísticas, Perfil) pasan a ser ramas de un
/// `StatefulShellRoute.indexedStack`, cada una con su propia URL
/// (`/`, `/movements`, `/statistics`, `/profile`) y su propio Navigator —
/// eso es lo que reemplaza al `_index`/`IndexedStack` manual de 4
/// posiciones que tenía el HomeShell viejo para estas 4 pantallas.
///
/// Todo lo que hoy es "pestaña virtual" (Cuentas, Categorías, Servicios,
/// Facturas y sus formularios) queda SIN TOCAR por ahora, colgado de la
/// rama "Inicio" — ver [HomeBranchScreen]. Migrarlas a rutas propias es
/// la fase siguiente del plan.
GoRouter buildAppRouter({
  required AuthViewModel authViewModel,
  required AccountViewModel accountViewModel,
  required TransactionViewModel transactionViewModel,
  required CategoryViewModel categoryViewModel,
  required MonthlyBalanceViewModel monthlyBalanceViewModel,
  required ServiceViewModel serviceViewModel,
  required InvoiceViewModel invoiceViewModel,
}) {
  // HomeBranchScreen (rama "Inicio") todavía maneja sus 13 pantallas
  // virtuales con índice + IndexedStack a mano, no con rutas — por eso
  // AppShellScreen necesita esta llave (para leer su estado: qué índice
  // interno tiene, qué acción mostrar en el header) y este Listenable
  // (para saber cuándo ese estado cambió y reconstruirse). El día que esas
  // pantallas pasen a ser rutas propias, esta plomería deja de hacer
  // falta.
  final homeBranchKey = GlobalKey<HomeBranchScreenState>();
  final homeBranchRevision = ValueNotifier<int>(0);

  return GoRouter(
    initialLocation: '/',
    // GoRouter no re-evalúa `redirect` solo porque cambió el estado de la
    // app — hay que decirle explícitamente cuándo hacerlo.
    // AuthViewModel ya notifica en cada cambio de sesión (ver
    // `_onAuthStateChange`), así que reusamos ese mismo Listenable en vez
    // de armar uno nuevo.
    refreshListenable: authViewModel,
    redirect: (context, state) {
      final isAuthenticated = authViewModel.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(viewModel: authViewModel),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShellScreen(
          navigationShell: navigationShell,
          homeBranchKey: homeBranchKey,
          homeBranchRevision: homeBranchRevision,
          authViewModel: authViewModel,
        ),
        branches: [
          // Rama 0 — Inicio (Dashboard + todo lo que todavía no tiene
          // ruta propia, ver HomeBranchScreen).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => HomeBranchScreen(
                  key: homeBranchKey,
                  authViewModel: authViewModel,
                  accountViewModel: accountViewModel,
                  transactionViewModel: transactionViewModel,
                  categoryViewModel: categoryViewModel,
                  monthlyBalanceViewModel: monthlyBalanceViewModel,
                  serviceViewModel: serviceViewModel,
                  invoiceViewModel: invoiceViewModel,
                  onChanged: () => homeBranchRevision.value++,
                  // "Movimientos" ahora es la rama 1 — StatefulNavigationShell.of
                  // encuentra el shell ambiente desde el context de esta ruta
                  // (que vive adentro de él) sin que AppShellScreen tenga que
                  // pasarle nada a HomeBranchScreen.
                  onGoToMovements: () =>
                      StatefulNavigationShell.of(context).goBranch(1),
                ),
              ),
            ],
          ),
          // Rama 1 — Movimientos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movements',
                builder: (context, state) => MovementsTab(
                  transactionViewModel: transactionViewModel,
                  currency: accountViewModel.primaryCurrency,
                ),
              ),
            ],
          ),
          // Rama 2 — Estadísticas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => StatisticsTab(
                  transactionViewModel: transactionViewModel,
                  categoryViewModel: categoryViewModel,
                  currency: accountViewModel.primaryCurrency,
                ),
              ),
            ],
          ),
          // Rama 3 — Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    ProfileScreen(viewModel: authViewModel),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
