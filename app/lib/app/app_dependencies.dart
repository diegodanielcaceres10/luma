import '../features/accounts/presentation/view_models/account_view_model.dart';
import '../features/accounts/presentation/view_models/monthly_balance_view_model.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/auth/presentation/view_models/preferences_view_model.dart';
import '../features/categories/presentation/view_models/category_view_model.dart';
import '../features/home/presentation/view_models/app_lock_view_model.dart';
import '../features/invoices/presentation/view_models/invoice_view_model.dart';
import '../features/services/presentation/view_models/service_view_model.dart';
import '../features/transactions/presentation/view_models/transaction_view_model.dart';

/// View models the route definitions in `routes/` wire into the screens.
class AppDependencies {
  const AppDependencies({
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.monthlyBalanceViewModel,
    required this.serviceViewModel,
    required this.invoiceViewModel,
    required this.preferencesViewModel,
    required this.appLockViewModel,
  });

  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final ServiceViewModel serviceViewModel;
  final InvoiceViewModel invoiceViewModel;
  final PreferencesViewModel preferencesViewModel;
  final AppLockViewModel appLockViewModel;
}
