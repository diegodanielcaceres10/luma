import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';

class StatisticsSummaryCardsRow extends StatelessWidget {
  final double income;
  final double expenses;
  final double netResult;
  final double? incomeChangePercent;
  final double? expenseChangePercent;
  final double? netChangePercent;
  final String currency;

  const StatisticsSummaryCardsRow({
    super.key,
    required this.income,
    required this.expenses,
    required this.netResult,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
    required this.netChangePercent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.arrow_downward_rounded,
            iconBackground: AppColors.authIncome,
            label: 'Ingresos',
            amount: income,
            changePercent: incomeChangePercent,
            isFavorable:
                incomeChangePercent == null ? null : incomeChangePercent! >= 0,
            currency: currency,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.arrow_upward_rounded,
            iconBackground: AppColors.authExpense,
            label: 'Gastos',
            amount: expenses,
            changePercent: expenseChangePercent,
            // For expenses, spending less than last month is the improvement.
            isFavorable: expenseChangePercent == null
                ? null
                : expenseChangePercent! <= 0,
            currency: currency,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBackground: AppColors.authAccentDark,
            label: 'Balance del mes',
            amount: netResult,
            changePercent: netChangePercent,
            isFavorable:
                netChangePercent == null ? null : netChangePercent! >= 0,
            currency: currency,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String label;
  final double amount;
  final double? changePercent;
  final bool? isFavorable;
  final String currency;

  const _SummaryCard({
    required this.icon,
    required this.iconBackground,
    required this.label,
    required this.amount,
    required this.changePercent,
    required this.isFavorable,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconBackground,
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.authTextSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatCurrency(amount, currency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            if (changePercent != null && isFavorable != null) ...[
              const SizedBox(height: 6),
              _ChangeIndicator(
                changePercent: changePercent!,
                isFavorable: isFavorable!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows the change vs. the previous month with an arrow and a color that
/// depends on [isFavorable]; for expenses, decreasing is favorable.
class _ChangeIndicator extends StatelessWidget {
  final double changePercent;
  final bool isFavorable;

  const _ChangeIndicator({
    required this.changePercent,
    required this.isFavorable,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFavorable ? AppColors.authAccent : AppColors.authExpense;
    final icon = changePercent >= 0
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final sign = changePercent > 0 ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '$sign${changePercent.toStringAsFixed(0)}% vs. mes anterior',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
