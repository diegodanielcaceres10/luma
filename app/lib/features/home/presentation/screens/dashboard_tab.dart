import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../../../transactions/data/models/transaction_entry.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';

/// Contenido de la pestaña "Inicio". No tiene Scaffold propio — vive dentro
/// del Scaffold del HomeShell, que es quien pone el bottomNavigationBar.
class DashboardTab extends StatelessWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final InvoiceViewModel invoiceViewModel;
  final VoidCallback? onSeeAllMovements;
  final ValueChanged<List<Account>> onOpenMonthlyBalances;
  final ValueChanged<String> onOpenAddTransaction;
  final VoidCallback onGoToAccounts;
  final VoidCallback onManageAccounts;
  final VoidCallback onGoToInvoices;
  final VoidCallback onGoToTransfers;

  const DashboardTab({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.monthlyBalanceViewModel,
    required this.invoiceViewModel,
    required this.onOpenMonthlyBalances,
    required this.onOpenAddTransaction,
    required this.onGoToAccounts,
    required this.onManageAccounts,
    required this.onGoToInvoices,
    required this.onGoToTransfers,
    this.onSeeAllMovements,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        accountViewModel,
        transactionViewModel,
        monthlyBalanceViewModel,
        invoiceViewModel,
      ]),
      builder: (context, _) {
        final pendingAccounts = monthlyBalanceViewModel.checked
            ? monthlyBalanceViewModel
                .pendingAccounts(accountViewModel.activeAccounts)
            : const <Account>[];

        // No active accounts — guide the user to create one.
        if (!accountViewModel.isLoading &&
            accountViewModel.activeAccounts.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _GreetingRow(
                initials: authViewModel.initials,
                firstName: authViewModel.displayName.split(' ').first,
              ),
              const SizedBox(height: 40),
              _NoAccountsCard(onGoToAccounts: onGoToAccounts),
            ],
          );
        }

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
              netResult: transactionViewModel.netResult,
              isLoadingNetResult: transactionViewModel.isLoading,
              pendingAccountsCount: pendingAccounts.length,
              onCompletePendingBalances: pendingAccounts.isEmpty
                  ? null
                  : () => onOpenMonthlyBalances(pendingAccounts),
              onManageAccounts: onManageAccounts,
            ),
            const SizedBox(height: 28),
            const _SectionHeader(title: 'Acciones rápidas'),
            const SizedBox(height: 12),
            _QuickActions(
              onAddIncome: () => onOpenAddTransaction('income'),
              onAddExpense: () => onOpenAddTransaction('expense'),
              onGoToInvoices: onGoToInvoices,
              onGoToTransfers: onGoToTransfers,
              pendingInvoicesCount: invoiceViewModel.pendingCount,
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

class _NoAccountsCard extends StatelessWidget {
  final VoidCallback onGoToAccounts;

  const _NoAccountsCard({required this.onGoToAccounts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.authAccent,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Creá tu primera cuenta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para empezar a registrar tus movimientos\nnecesitás al menos una cuenta activa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.authTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.authAccent,
                foregroundColor: AppColors.authBackgroundBottom,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onGoToAccounts,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear cuenta'),
            ),
          ),
        ],
      ),
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
          backgroundColor: AppColors.authAccentDark.withValues(alpha: 0.35),
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
  final double netResult;
  final bool isLoadingNetResult;
  final int pendingAccountsCount;
  final VoidCallback? onCompletePendingBalances;
  final VoidCallback onManageAccounts;

  const _BalanceCard({
    required this.isLoading,
    required this.total,
    required this.currency,
    required this.netResult,
    required this.isLoadingNetResult,
    required this.onManageAccounts,
    this.pendingAccountsCount = 0,
    this.onCompletePendingBalances,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/balance_card_bg.png'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Balance general del mes',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                InkWell(
                  onTap: onManageAccounts,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child:
                        Icon(Icons.settings, color: Colors.white70, size: 30),
                  ),
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
            isLoadingNetResult
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        netResult >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: netResult >= 0
                            ? AppColors.authAccent
                            : AppColors.authExpense,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${netResult >= 0 ? '+' : ''}'
                        '${formatCurrency(netResult, currency)} este mes '
                        '(ingresos - gastos)',
                        style: TextStyle(
                          color: netResult >= 0
                              ? AppColors.authAccent
                              : AppColors.authExpense,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
            if (pendingAccountsCount > 0) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              _PendingBalancesAlert(
                count: pendingAccountsCount,
                onTap: onCompletePendingBalances,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingBalancesAlert extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _PendingBalancesAlert({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = count == 1
        ? 'Falta cargar el saldo inicial de 1 cuenta este mes'
        : 'Faltan cargar los saldos iniciales de $count cuentas este mes';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFBBF24), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const Text(
            'Completar',
            style: TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFFBBF24), size: 16),
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
  final VoidCallback onGoToInvoices;
  final VoidCallback onGoToTransfers;
  final int pendingInvoicesCount;

  const _QuickActions({
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onGoToInvoices,
    required this.onGoToTransfers,
    this.pendingInvoicesCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
        ),
        const SizedBox(height: 12),
        _QuickActionCard(
          icon: Icons.request_page_outlined,
          iconColor: AppColors.authAccent,
          title: 'Facturas por pagar',
          subtitle: pendingInvoicesCount > 0
              ? '$pendingInvoicesCount pendiente${pendingInvoicesCount == 1 ? '' : 's'} este mes'
              : 'Revisá el estado de tus facturas',
          onTap: onGoToInvoices,
          isFullWidth: true,
        ),
        const SizedBox(height: 12),
        _QuickActionCard(
          icon: Icons.swap_horiz_rounded,
          iconColor: AppColors.authAccent,
          title: 'Transferencias entre cuentas',
          subtitle: 'Movés dinero de una cuenta a otra',
          onTap: onGoToTransfers,
          isFullWidth: true,
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
  final bool isFullWidth;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: AppColors.authCardFill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.authCardBorder),
          ),
          child: isFullWidth
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: iconColor.withValues(alpha: 0.85),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            style: AppTextStyles.authSubtitle
                                .copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.authTextFooter, size: 18),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: iconColor.withValues(alpha: 0.85),
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

    return card;
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
        final hasCategory = m.category.id != null;
        final categoryColor = hasCategory
            ? colorFromHex(m.category.color, fallback: AppColors.authAccent)
            : Colors.transparent;
        final sign = m.isIncome ? '+' : '-';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: hasCategory
                    ? categoryColor.withValues(
                        alpha: categoryIconBackgroundAlpha(m.category.icon))
                    : Colors.transparent,
                child: hasCategory
                    ? CategoryGlyph(
                        icon: m.category.icon,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
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
