import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/login_screen.dart';
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

    _authViewModel = AuthViewModel();
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
      home: LoginScreen(
        viewModel: _authViewModel,
      ),
    );
  }
}
