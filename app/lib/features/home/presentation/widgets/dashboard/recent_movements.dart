import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_text_styles.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../transactions/data/models/transaction_entry.dart';

class DashboardRecentMovements extends StatelessWidget {
  final bool isLoading;
  final List<TransactionEntry> movements;
  final String currency;

  const DashboardRecentMovements({
    super.key,
    required this.isLoading,
    required this.movements,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.authCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.authCardBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.authAccent,
            ),
          ),
        ),
      );
    }

    if (movements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.authCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.authCardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.authTextSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Todavía no hay movimientos este mes.',
              textAlign: TextAlign.center,
              style: AppTextStyles.authSubtitle,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < movements.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.authCardBorder),
            _buildMovementRow(movements[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildMovementRow(TransactionEntry m) {
    final sign = m.isIncome ? '+' : '-';
    final color = m.isTransfer
        ? AppColors.authTransfer
        : m.isIncome
            ? AppColors.authIncome
            : AppColors.authExpense;

    final icon = m.isTransfer
        ? Icons.swap_horiz_rounded
        : m.isIncome
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.description?.isNotEmpty == true
                      ? m.description!
                      : m.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(m.date),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${formatCurrency(m.amount, currency)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.3,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.isIncome ? 'Ingreso' : m.category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.authTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
