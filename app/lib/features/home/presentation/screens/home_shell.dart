import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../transactions/presentation/screens/movements_tab.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../widgets/placeholder_tab.dart';
import 'dashboard_tab.dart';

class HomeShell extends StatefulWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;

  const HomeShell({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _movementsLoaded = false;

  void _onTabTap(int index) {
    setState(() => _index = index);

    // Carga perezosa: el historial completo de transacciones recién se
    // pide la primera vez que se entra a "Movimientos", no al arrancar.
    if (index == 1 && !_movementsLoaded) {
      _movementsLoaded = true;
      widget.transactionViewModel.loadAllTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(
        authViewModel: widget.authViewModel,
        accountViewModel: widget.accountViewModel,
        transactionViewModel: widget.transactionViewModel,
        categoryViewModel: widget.categoryViewModel,
      ),
      MovementsTab(
        transactionViewModel: widget.transactionViewModel,
        currency: widget.accountViewModel.primaryCurrency,
      ),
      const PlaceholderTab(
          icon: Icons.bar_chart_rounded, label: 'Estadísticas'),
      ProfileScreen(viewModel: widget.authViewModel),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        onTap: _onTabTap,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'Inicio'),
    (Icons.history_rounded, 'Movimientos'),
    (Icons.bar_chart_rounded, 'Estadísticas'),
    (Icons.person_outline_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final isSelected = i == currentIndex;
          final color = isSelected ? AppColors.primary : AppColors.textMuted;

          return InkWell(
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$1, color: color),
                  Text(
                    item.$2,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
