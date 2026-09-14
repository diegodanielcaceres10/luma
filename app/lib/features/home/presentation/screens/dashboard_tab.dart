import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../transactions/data/models/transaction_entry.dart';
import '../../../transactions/presentation/screens/add_transaction_screen.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';

/// Contenido de la pestaña "Inicio". No tiene Scaffold propio — vive dentro
/// del Scaffold del HomeShell, que es quien pone el bottomNavigationBar.
class DashboardTab extends StatelessWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final VoidCallback? onSeeAllMovements;

  const DashboardTab({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    this.onSeeAllMovements,
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
    return ListenableBuilder(
      listenable: Listenable.merge([accountViewModel, transactionViewModel]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _GreetingRow(
              initials: authViewModel.initials,
              firstName: authViewModel.displayName.split(' ').first,
            ),
            const SizedBox(height: 20),
            _BalanceCard(
              isLoading: accountViewModel.isLoading,
              total: accountViewModel.totalBalance,
              currency: accountViewModel.primaryCurrency,
            ),
            const SizedBox(height: 28),
            const _SectionHeader(title: 'Acciones rápidas'),
            const SizedBox(height: 12),
            _QuickActions(
              onAddIncome: () => _openAddTransaction(context, 'income'),
              onAddExpense: () => _openAddTransaction(context, 'expense'),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Últimos movimientos',
              onSeeAll: onSeeAllMovements,
            ),
            const SizedBox(height: 8),
            _RecentMovements(
              isLoading: transactionViewModel.isLoading,
              movements: transactionViewModel.recentMovements,
              currency: accountViewModel.primaryCurrency,
            ),
          ],
        );
      },
    );
  }
}

class _GreetingRow extends StatelessWidget {
  final String initials;
  final String firstName;

  const _GreetingRow({required this.initials, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.authAccentDark.withOpacity(0.35),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.authTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $firstName 👋',
                style: AppTextStyles.authTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 2),
              const Text(
                'Aquí tienes un resumen de tus finanzas.',
                style: AppTextStyles.authSubtitle,
              ),
            ],
          ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.authAccentDark,
                  AppColors.authBackgroundBottom
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Balance general del mes',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                        formatCurrency(total, currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        color: AppColors.authAccent, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '+12% vs. mes anterior',
                      style: TextStyle(
                        color: AppColors.authAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      child: const Icon(Icons.credit_card_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total pendiente de pagar',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '\$ 320,00',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver detalles',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Decorative highlight, top-right — echoes the login screen glow.
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.authTextPrimary,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.authTextSecondary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ver todas', style: TextStyle(fontSize: 13)),
              Icon(Icons.chevron_right_rounded, size: 16),
            ],
          ),
        ),
      ],
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
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.authIncome,
            title: 'Agregar ingreso',
            subtitle: 'Sumá dinero a tu cuenta',
            onTap: onAddIncome,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.authExpense,
            title: 'Agregar gasto',
            subtitle: 'Registrá un nuevo gasto',
            onTap: onAddExpense,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authCardFill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.authCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: iconColor.withOpacity(0.85),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.authTextFooter, size: 18),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.authSubtitle.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
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
          style: AppTextStyles.authSubtitle,
        ),
      );
    }

    final dateFormat = DateFormat('d MMM yyyy', 'es');

    return Column(
      children: movements.map((m) {
        final color = m.isIncome
            ? AppColors.authIncome
            : colorFromHex(m.category.color, fallback: AppColors.authExpense);
        final sign = m.isIncome ? '+' : '-';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.85),
                child: Icon(
                  m.isIncome
                      ? Icons.arrow_downward_rounded
                      : iconFromName(m.category.icon),
                  color: Colors.white,
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
                      style: AppTextStyles.authBody,
                    ),
                    Text(
                      dateFormat.format(m.date),
                      style: AppTextStyles.authSubtitle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${formatCurrency(m.amount, currency)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: m.isIncome
                          ? AppColors.authIncome
                          : AppColors.authExpense,
                    ),
                  ),
                  Text(
                    m.isIncome ? 'Ingreso' : m.category.name,
                    style: AppTextStyles.authSubtitle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
