import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/screens/account_form_tab.dart';
import '../../../accounts/presentation/screens/accounts_tab.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../budgets/data/models/budget.dart';
import '../../../budgets/presentation/screens/budget_form_tab.dart';
import '../../../budgets/presentation/screens/budgets_tab.dart';
import '../../../budgets/presentation/view_models/budget_view_model.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/screens/categories_tab.dart';
import '../../../categories/presentation/screens/category_form_tab.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
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

/// Pestañas a las que solo se llega desde el drawer o desde otra pestaña,
/// sin entrada propia en el bottom nav.
const _accountsTabIndex = 4;
const _accountFormTabIndex = 5;
const _categoriesTabIndex = 6;
const _categoryFormTabIndex = 7;
const _budgetsTabIndex = 8;
const _budgetFormTabIndex = 9;

class HomeShell extends StatefulWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final BudgetViewModel budgetViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;

  const HomeShell({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.budgetViewModel,
    required this.monthlyBalanceViewModel,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _movementsLoaded = false;

  // Cuenta que se está editando en la pestaña de formulario; null = alta.
  Account? _editingAccount;
  int _accountFormNonce = 0;

  // Categoría que se está editando; null = alta.
  Category? _editingCategory;
  String _categoryInitialType = 'expense';
  int _categoryFormNonce = 0;

  // Presupuesto que se está editando; null = alta.
  Budget? _editingBudget;
  int _budgetFormNonce = 0;

  void _onTabTap(int index) {
    setState(() => _index = index);

    // Carga perezosa: el historial completo de transacciones recién se
    // pide la primera vez que se entra a "Movimientos", no al arrancar.
    if (index == 1 && !_movementsLoaded) {
      _movementsLoaded = true;
      widget.transactionViewModel.loadAllTransactions();
    }
  }

  void _openAccountForm(Account? account) {
    setState(() {
      _editingAccount = account;
      if (account == null) _accountFormNonce++;
      _index = _accountFormTabIndex;
    });
  }

  void _closeAccountForm() {
    setState(() {
      _editingAccount = null;
      _index = _accountsTabIndex;
    });
  }

  void _openCategoryForm(Category? category, {String initialType = 'expense'}) {
    setState(() {
      _editingCategory = category;
      _categoryInitialType = initialType;
      if (category == null) _categoryFormNonce++;
      _index = _categoryFormTabIndex;
    });
  }

  void _closeCategoryForm() {
    setState(() {
      _editingCategory = null;
      _index = _categoriesTabIndex;
    });
  }

  void _openBudgetForm(Budget? budget) {
    setState(() {
      _editingBudget = budget;
      if (budget == null) _budgetFormNonce++;
      _index = _budgetFormTabIndex;
    });
  }

  void _closeBudgetForm() {
    setState(() {
      _editingBudget = null;
      _index = _budgetsTabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(
        authViewModel: widget.authViewModel,
        accountViewModel: widget.accountViewModel,
        transactionViewModel: widget.transactionViewModel,
        categoryViewModel: widget.categoryViewModel,
        monthlyBalanceViewModel: widget.monthlyBalanceViewModel,
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
      AccountsTab(
        accountViewModel: widget.accountViewModel,
        onOpenForm: _openAccountForm,
      ),
      AccountFormTab(
        key: ValueKey(_editingAccount?.id ?? 'new-$_accountFormNonce'),
        userId: widget.authViewModel.userId ?? '',
        accountViewModel: widget.accountViewModel,
        account: _editingAccount,
        onDone: _closeAccountForm,
      ),
      CategoriesTab(
        categoryViewModel: widget.categoryViewModel,
        onEdit: (category) => _openCategoryForm(category),
      ),
      CategoryFormTab(
        key: ValueKey(_editingCategory?.id ?? 'new-$_categoryFormNonce'),
        userId: widget.authViewModel.userId ?? '',
        categoryViewModel: widget.categoryViewModel,
        category: _editingCategory,
        initialType: _categoryInitialType,
        onDone: _closeCategoryForm,
      ),
      BudgetsTab(
        budgetViewModel: widget.budgetViewModel,
        currency: widget.accountViewModel.primaryCurrency,
        onEdit: (budget) => _openBudgetForm(budget),
      ),
      BudgetFormTab(
        key: ValueKey(_editingBudget?.id ?? 'new-$_budgetFormNonce'),
        userId: widget.authViewModel.userId ?? '',
        budgetViewModel: widget.budgetViewModel,
        categoryViewModel: widget.categoryViewModel,
        budget: _editingBudget,
        onDone: _closeBudgetForm,
      ),
    ];

    return Scaffold(
      drawer: _AppDrawer(
        currentIndex: _index,
        onSelect: _onTabTap,
        userId: widget.authViewModel.userId,
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
      case _accountsTabIndex:
        return IconButton(
          onPressed: () => _openAccountForm(null),
          icon: const Icon(Icons.add_rounded),
          color: AppColors.authTextPrimary,
        );
      case _categoriesTabIndex:
        return IconButton(
          onPressed: () => _openCategoryForm(null),
          icon: const Icon(Icons.add_rounded),
          color: AppColors.authTextPrimary,
        );
      case _budgetsTabIndex:
        return IconButton(
          onPressed: () => _openBudgetForm(null),
          icon: const Icon(Icons.add_rounded),
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

  const _AppDrawer({
    required this.currentIndex,
    required this.onSelect,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isAccountsSection =
        currentIndex == _accountsTabIndex || currentIndex == _accountFormTabIndex;
    final isCategoriesSection = currentIndex == _categoriesTabIndex ||
        currentIndex == _categoryFormTabIndex;
    final isBudgetsSection =
        currentIndex == _budgetsTabIndex || currentIndex == _budgetFormTabIndex;

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
              leading: Icon(
                Icons.account_balance_wallet_outlined,
                color: isAccountsSection
                    ? AppColors.authAccent
                    : AppColors.authTextSecondary,
              ),
              title: Text(
                'Cuentas',
                style: TextStyle(
                  color: isAccountsSection
                      ? AppColors.authAccent
                      : AppColors.authTextSecondary,
                  fontWeight:
                      isAccountsSection ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isAccountsSection,
              selectedTileColor: AppColors.authCardFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              onTap: userId == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onSelect(_accountsTabIndex);
                    },
            ),
            ListTile(
              leading: Icon(
                Icons.sell_outlined,
                color: isCategoriesSection
                    ? AppColors.authAccent
                    : AppColors.authTextSecondary,
              ),
              title: Text(
                'Categorías',
                style: TextStyle(
                  color: isCategoriesSection
                      ? AppColors.authAccent
                      : AppColors.authTextSecondary,
                  fontWeight:
                      isCategoriesSection ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isCategoriesSection,
              selectedTileColor: AppColors.authCardFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              onTap: userId == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onSelect(_categoriesTabIndex);
                    },
            ),
            ListTile(
              leading: Icon(
                Icons.pie_chart_outline_rounded,
                color: isBudgetsSection
                    ? AppColors.authAccent
                    : AppColors.authTextSecondary,
              ),
              title: Text(
                'Presupuestos',
                style: TextStyle(
                  color: isBudgetsSection
                      ? AppColors.authAccent
                      : AppColors.authTextSecondary,
                  fontWeight:
                      isBudgetsSection ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isBudgetsSection,
              selectedTileColor: AppColors.authCardFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              onTap: userId == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onSelect(_budgetsTabIndex);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
