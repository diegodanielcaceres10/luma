import 'package:go_router/go_router.dart';

import '../features/accounts/presentation/view_models/account_view_model.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/categories/presentation/view_models/category_view_model.dart';
import '../features/home/presentation/screens/home_shell.dart';
import '../features/invoices/presentation/view_models/invoice_view_model.dart';
import '../features/monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../features/services/presentation/view_models/service_view_model.dart';
import '../features/transactions/presentation/view_models/transaction_view_model.dart';

/// Fase 1 de la migración de la navegación por tabs a rutas (plan
/// acordado con el usuario). Por ahora esto solo separa "con sesión" de
/// "sin sesión":
///   - `/login`  → LoginScreen
///   - `/`       → HomeShell, TAL CUAL está hoy (sigue manejando sus 17
///                 "pestañas" internas con el índice + IndexedStack
///                 viejo). Las fases siguientes van a ir reemplazando esas
///                 pestañas por rutas propias, una por una, sin tocar las
///                 demás.
///
/// Los ViewModels se pasan ya construidos desde `app.dart` (misma
/// instancia que arma `_loadUserData`, etc.) — no se crea estado nuevo
/// acá, esto solo define qué widget corresponde a cada URL.
GoRouter buildAppRouter({
  required AuthViewModel authViewModel,
  required AccountViewModel accountViewModel,
  required TransactionViewModel transactionViewModel,
  required CategoryViewModel categoryViewModel,
  required MonthlyBalanceViewModel monthlyBalanceViewModel,
  required ServiceViewModel serviceViewModel,
  required InvoiceViewModel invoiceViewModel,
}) {
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
      GoRoute(
        path: '/',
        builder: (context, state) => HomeShell(
          authViewModel: authViewModel,
          accountViewModel: accountViewModel,
          transactionViewModel: transactionViewModel,
          categoryViewModel: categoryViewModel,
          monthlyBalanceViewModel: monthlyBalanceViewModel,
          serviceViewModel: serviceViewModel,
          invoiceViewModel: invoiceViewModel,
        ),
      ),
    ],
  );
}
