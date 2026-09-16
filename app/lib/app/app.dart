import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/accounts/data/repositories/account_repository.dart';
import '../features/accounts/data/services/account_service.dart';
import '../features/accounts/presentation/view_models/account_view_model.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/data/services/auth_service.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/budgets/data/repositories/budget_repository.dart';
import '../features/budgets/data/services/budget_service.dart';
import '../features/budgets/presentation/view_models/budget_view_model.dart';
import '../features/categories/data/repositories/category_repository.dart';
import '../features/categories/data/services/category_service.dart';
import '../features/categories/presentation/view_models/category_view_model.dart';
import '../features/home/presentation/screens/home_shell.dart';
import '../features/transactions/data/repositories/transaction_repository.dart';
import '../features/transactions/data/services/transaction_service.dart';
import '../features/transactions/presentation/view_models/transaction_view_model.dart';
import 'theme/app_theme.dart';

class LumaApp extends StatefulWidget {
  const LumaApp({super.key});

  @override
  State<LumaApp> createState() => _LumaAppState();
}

class _LumaAppState extends State<LumaApp> {
  late final AuthViewModel _authViewModel;
  late final AccountViewModel _accountViewModel;
  late final TransactionViewModel _transactionViewModel;
  late final CategoryViewModel _categoryViewModel;
  late final BudgetViewModel _budgetViewModel;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;

    final authRepository = AuthRepository(AuthService(client));
    _authViewModel = AuthViewModel(authRepository);

    final accountRepository = AccountRepository(AccountService(client));
    _accountViewModel = AccountViewModel(accountRepository);

    final transactionRepository =
        TransactionRepository(TransactionService(client));
    _transactionViewModel = TransactionViewModel(transactionRepository);

    final categoryRepository = CategoryRepository(CategoryService(client));
    _categoryViewModel = CategoryViewModel(categoryRepository);

    final budgetRepository = BudgetRepository(BudgetService(client));
    _budgetViewModel = BudgetViewModel(budgetRepository);

    _authViewModel.addListener(_onAuthChanged);
    if (_authViewModel.isAuthenticated) {
      _loadUserData();
    }
  }

  void _onAuthChanged() {
    if (_authViewModel.isAuthenticated) {
      _loadUserData();
    }
  }

  void _loadUserData() {
    _accountViewModel.loadAccounts();
    _transactionViewModel.loadCurrentMonth();
    _categoryViewModel.loadCategories();
    _budgetViewModel.loadBudgets();
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthChanged);
    _authViewModel.dispose();
    _accountViewModel.dispose();
    _transactionViewModel.dispose();
    _categoryViewModel.dispose();
    _budgetViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: _authViewModel,
        builder: (context, _) {
          return _authViewModel.isAuthenticated
              ? HomeShell(
                  authViewModel: _authViewModel,
                  accountViewModel: _accountViewModel,
                  transactionViewModel: _transactionViewModel,
                  categoryViewModel: _categoryViewModel,
                  budgetViewModel: _budgetViewModel,
                )
              : LoginScreen(viewModel: _authViewModel);
        },
      ),
    );
  }
}
