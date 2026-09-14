import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../transactions/data/models/transaction_entry.dart';
import '../../../transactions/presentation/screens/add_transaction_screen.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';

class HomeScreen extends StatelessWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;

  const HomeScreen({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
  });

  void _openAddTransaction(BuildContext context, String type) {
    final userId = authViewModel.userId;
    if (userId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          type: type,
          userId: userId,
          accountViewModel: accountViewModel,
          categoryViewModel: categoryViewModel,
          transactionViewModel: transactionViewModel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable:
              Listenable.merge([accountViewModel, transactionViewModel]),
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Header(name: authViewModel.displayName),
                const SizedBox(height: 20),
                _BalanceCard(
                  isLoading: accountViewModel.isLoading,
                  total: accountViewModel.totalBalance,
                  currency: accountViewModel.primaryCurrency,
                ),
                const SizedBox(height: 20),
                _QuickActions(
                  onAddIncome: () => _openAddTransaction(context, 'income'),
                  onAddExpense: () => _openAddTransaction(context, 'expense'),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Gastos por categoría',
                  child: _CategoryBreakdown(
                    isLoading: transactionViewModel.isLoading,
                    breakdown: transactionViewModel.categoryBreakdown,
                    currency: accountViewModel.primaryCurrency,
                  ),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Últimos movimientos',
                  child: _RecentMovements(
                    isLoading: transactionViewModel.isLoading,
                    movements: transactionViewModel.recentMovements,
                    currency: accountViewModel.primaryCurrency,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;

  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Buenos días,', style: AppTextStyles.subtitle),
              Text(
                '$name 👋',
                style: AppTextStyles.title.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aquí tienes un resumen de tus finanzas de este mes.',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
        const IconButton(
          onPressed: null,
          icon: Icon(Icons.notifications_none_rounded),
          color: AppColors.text,
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final bool isLoading;
  final double total;
  final String currency;

  const _BalanceCard({
    required this.isLoading,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo total',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Icon(Icons.visibility_outlined, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 8),
          isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '${total.toStringAsFixed(2)} $currency',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  color: Colors.greenAccent, size: 18),
              SizedBox(width: 4),
              Text(
                '+320,50 €',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'vs. mes anterior',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;

  const _QuickActions({
    required this.onAddIncome,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_rounded, 'Añadir\ningreso', AppColors.primary, onAddIncome),
      (Icons.remove_rounded, 'Añadir\ngasto', AppColors.error, onAddExpense),
      (Icons.bar_chart_rounded, 'Ver\nestadísticas', AppColors.primary, null),
      (Icons.credit_card_rounded, 'Categorías', AppColors.primary, null),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _QuickActionButton(
                  icon: a.$1,
                  label: a.$2,
                  color: a.$3,
                  onTap: a.$4,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextButton(
                onPressed: null,
                child: Row(
                  children: [
                    Text('Ver todos'),
                    Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final bool isLoading;
  final List<CategoryTotal> breakdown;
  final String currency;

  const _CategoryBreakdown({
    required this.isLoading,
    required this.breakdown,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (breakdown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Todavía no hay gastos este mes.',
          style: AppTextStyles.subtitle,
        ),
      );
    }

    return Column(
      children: breakdown.map((c) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorFromHex(c.category.color,
                      fallback: AppColors.primary),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(iconFromName(c.category.icon),
                  size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.category.name, style: AppTextStyles.body),
              ),
              Text('${c.amount.toStringAsFixed(2)} $currency',
                  style: AppTextStyles.body),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text(
                  '${c.percent.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecentMovements extends StatelessWidget {
  final bool isLoading;
  final List<TransactionEntry> movements;
  final String currency;

  const _RecentMovements({
    required this.isLoading,
    required this.movements,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (movements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Todavía no hay movimientos este mes.',
          style: AppTextStyles.subtitle,
        ),
      );
    }

    final dateFormat = DateFormat('d MMM. yyyy', 'es');

    return Column(
      children: movements.map((m) {
        final color = m.isIncome
            ? AppColors.success
            : colorFromHex(m.category.color, fallback: AppColors.primary);
        final sign = m.isIncome ? '+' : '-';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  m.isIncome
                      ? Icons.arrow_downward_rounded
                      : iconFromName(m.category.icon),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.description?.isNotEmpty == true
                          ? m.description!
                          : m.category.name,
                      style: AppTextStyles.body,
                    ),
                    Text(
                      '${m.category.name} · ${dateFormat.format(m.date)}',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign${m.amount.toStringAsFixed(2)} $currency',
                style: AppTextStyles.body.copyWith(
                  color: m.isIncome ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Inicio'),
      (Icons.history_rounded, 'Movimientos'),
      (Icons.bar_chart_rounded, 'Estadísticas'),
      (Icons.person_outline_rounded, 'Perfil'),
    ];

    return BottomAppBar(
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map(
              (item) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.$1,
                    color: item.$1 == Icons.home_rounded
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 11,
                      color: item.$1 == Icons.home_rounded
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
