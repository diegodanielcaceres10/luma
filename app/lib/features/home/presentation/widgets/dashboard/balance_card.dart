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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.authCardBorder.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/balance_card_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Balance general del mes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  isLoading
                      ? const SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          formatCurrency(total, currency),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                        ),
                  const SizedBox(height: 10),
                  isLoadingNetResult
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (netResult >= 0
                                    ? AppColors.authAccent
                                    : AppColors.authExpense)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (netResult >= 0
                                      ? AppColors.authAccent
                                      : AppColors.authExpense)
                                  .withValues(alpha: 0.32),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                netResult >= 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: netResult >= 0
                                    ? AppColors.authAccent
                                    : AppColors.authExpense,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '${netResult >= 0 ? '+' : ''}'
                                  '${formatCurrency(netResult, currency)} este mes',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: netResult >= 0
                                        ? AppColors.authAccent
                                        : AppColors.authExpense,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  if (isLoadingPendingInvoices) ...[
                    const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Servicios pendientes de pagar: '
                                '${formatCurrency(pendingInvoicesTotal, currency)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (pendingInvoicesCount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.request_page_outlined,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Facturas por pagar: $pendingInvoicesCount',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  if (pendingAccountIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFBBF24), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFDE68A),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
