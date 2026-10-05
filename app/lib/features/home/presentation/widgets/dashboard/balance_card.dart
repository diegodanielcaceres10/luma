import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../accounts/data/models/account.dart';
import 'balance_accounts_expander.dart';

class DashboardBalanceCard extends StatelessWidget {
  final bool isLoading;
  final double total;
  final String currency;

  /// Income minus expenses for the current month, plus that same month's
  /// undeclared adjustments (see
  /// [TransactionViewModel.netResultWithUncontrolled]).
  final double netResult;
  final bool isLoadingNetResult;

  /// Ids of the accounts without an opening balance this month.
  final Set<String> pendingAccountIds;
  final ValueChanged<String> onCompletePendingBalance;
  final VoidCallback onManageAccounts;

  /// Active accounts, for the breakdown that expands in the card.
  final List<Account> accounts;
  final double pendingInvoicesTotal;

  /// Pending invoices (neither paid nor cancelled) for the current month.
  final int pendingInvoicesCount;
  final bool isLoadingPendingInvoices;

  const DashboardBalanceCard({
    super.key,
    required this.isLoading,
    required this.total,
    required this.currency,
    required this.netResult,
    required this.isLoadingNetResult,
    required this.onManageAccounts,
    required this.accounts,
    required this.onCompletePendingBalance,
    this.pendingAccountIds = const {},
    this.pendingInvoicesTotal = 0,
    this.pendingInvoicesCount = 0,
    this.isLoadingPendingInvoices = false,
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
                        '${formatCurrency(netResult, currency)} este mes',
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
            if (isLoadingPendingInvoices) ...[
              const SizedBox(height: 8),
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            ] else ...[
              if (pendingInvoicesTotal > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Servicios pendientes de pagar: '
                        '${formatCurrency(pendingInvoicesTotal, currency)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (pendingInvoicesCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.request_page_outlined,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Facturas por pagar: $pendingInvoicesCount',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            if (pendingAccountIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              _PendingBalancesAlert(count: pendingAccountIds.length),
            ],
            const SizedBox(height: 8),
            BalanceAccountsExpander(
              accounts: accounts,
              currency: currency,
              onManageAccounts: onManageAccounts,
              pendingAccountIds: pendingAccountIds,
              onCompletePendingBalance: onCompletePendingBalance,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingBalancesAlert extends StatelessWidget {
  final int count;

  const _PendingBalancesAlert({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count == 1
        ? 'Falta cargar el saldo inicial de 1 cuenta este mes'
        : 'Faltan cargar los saldos iniciales de $count cuentas este mes';

    return Row(
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
      ],
    );
  }
}
