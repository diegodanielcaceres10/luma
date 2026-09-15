import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../../../accounts/presentation/screens/accounts_screen.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../transactions/presentation/screens/movements_tab.dart';
import '../../../transactions/presentation/screens/statistics_tab.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../widgets/luma_header.dart';
import 'dashboard_tab.dart';

/// Accesos compartidos entre el bottom nav y el drawer del menú hamburguesa.
const _navItems = [
  (Icons.home_rounded, 'Inicio'),
  (Icons.trending_up_rounded, 'Movimientos'),
  (Icons.bar_chart_rounded, 'Estadísticas'),
  (Icons.person_outline_rounded, 'Perfil'),
];

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
        onSeeAllMovements: () => _onTabTap(1),
      ),
      MovementsTab(
        transactionViewModel: widget.transactionViewModel,
        currency: widget.accountViewModel.primaryCurrency,
      ),
      StatisticsTab(
        transactionViewModel: widget.transactionViewModel,
        currency: widget.accountViewModel.primaryCurrency,
      ),
      ProfileScreen(viewModel: widget.authViewModel),
    ];

    return Scaffold(
      drawer: _AppDrawer(
        currentIndex: _index,
        onSelect: _onTabTap,
        userId: widget.authViewModel.userId,
        categoryViewModel: widget.categoryViewModel,
        accountViewModel: widget.accountViewModel,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.authBackgroundTop,
              AppColors.authBackgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              LumaHeader(trailing: _headerAction()),
              Expanded(child: IndexedStack(index: _index, children: tabs)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        onTap: _onTabTap,
      ),
    );
  }

  /// Acción a la derecha del header, según la pestaña activa.
  Widget? _headerAction() {
    switch (_index) {
      case 0:
        return const IconButton(
          onPressed: null,
          icon: Icon(Icons.notifications_none_rounded),
          color: AppColors.authTextPrimary,
        );
      case 3:
        return const IconButton(
          onPressed: null,
          icon: Icon(Icons.settings_outlined),
          color: AppColors.authTextPrimary,
        );
      default:
        return null;
    }
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.authBackgroundBottom,
        border: Border(top: BorderSide(color: AppColors.authCardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isSelected = i == currentIndex;
              final color =
                  isSelected ? AppColors.authAccent : AppColors.authTextFooter;

              return InkWell(
                onTap: () => onTap(i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1, color: color, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        item.$2,
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: 16,
                        height: 2,
                        child: isSelected
                            ? const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.authAccent,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final String? userId;
  final CategoryViewModel categoryViewModel;
  final AccountViewModel accountViewModel;

  const _AppDrawer({
    required this.currentIndex,
    required this.onSelect,
    required this.userId,
    required this.categoryViewModel,
    required this.accountViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.authBackgroundBottom,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  LumaLogo(size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Luma',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.authCardBorder),
            const SizedBox(height: 8),
            ...List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isSelected = i == currentIndex;
              final color = isSelected
                  ? AppColors.authAccent
                  : AppColors.authTextSecondary;

              return ListTile(
                leading: Icon(item.$1, color: color),
                title: Text(
                  item.$2,
                  style: TextStyle(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                selectedTileColor: AppColors.authCardFill,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(i);
                },
              );
            }),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.authCardBorder),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.authTextSecondary),
              title: const Text(
                'Cuentas',
                style: TextStyle(
                  color: AppColors.authTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              onTap: userId == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AccountsScreen(
                            userId: userId!,
                            accountViewModel: accountViewModel,
                          ),
                        ),
                      );
                    },
            ),
            ListTile(
              leading: const Icon(Icons.sell_outlined,
                  color: AppColors.authTextSecondary),
              title: const Text(
                'Categorías',
                style: TextStyle(
                  color: AppColors.authTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              onTap: userId == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CategoriesScreen(
                            userId: userId!,
                            categoryViewModel: categoryViewModel,
                          ),
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
