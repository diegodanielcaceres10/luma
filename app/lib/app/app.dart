import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/data/services/auth_service.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import 'theme/app_theme.dart';

class LumaApp extends StatefulWidget {
  const LumaApp({super.key});

  @override
  State<LumaApp> createState() => _LumaAppState();
}

class _LumaAppState extends State<LumaApp> {
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    final authService = AuthService(Supabase.instance.client);
    final authRepository = AuthRepository(authService);
    _authViewModel = AuthViewModel(authRepository);
  }

  @override
  void dispose() {
    _authViewModel.dispose();
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
              ? HomeScreen(viewModel: _authViewModel)
              : LoginScreen(viewModel: _authViewModel);
        },
      ),
    );
  }
}
