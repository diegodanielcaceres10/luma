import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/accounts/data/repositories/account_repository.dart';
import '../features/accounts/data/services/account_service.dart';
import '../features/accounts/presentation/view_models/account_view_model.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/data/services/auth_service.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/home/presentation/screens/home_screen.dart';
import 'theme/app_theme.dart';

class LumaApp extends StatefulWidget {
  const LumaApp({super.key});

  @override
  State<LumaApp> createState() => _LumaAppState();
}

class _LumaAppState extends State<LumaApp> {
  late final AuthViewModel _authViewModel;
  late final AccountViewModel _accountViewModel;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;

    final authRepository = AuthRepository(AuthService(client));
    _authViewModel = AuthViewModel(authRepository);

    final accountRepository = AccountRepository(AccountService(client));
    _accountViewModel = AccountViewModel(accountRepository);

    _authViewModel.addListener(_onAuthChanged);
    if (_authViewModel.isAuthenticated) {
      _accountViewModel.loadAccounts();
    }
  }

  void _onAuthChanged() {
    if (_authViewModel.isAuthenticated) {
      _accountViewModel.loadAccounts();
    }
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthChanged);
    _authViewModel.dispose();
    _accountViewModel.dispose();
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
              ? HomeScreen(
                  authViewModel: _authViewModel,
                  accountViewModel: _accountViewModel,
                )
              : LoginScreen(viewModel: _authViewModel);
        },
      ),
    );
  }
}
