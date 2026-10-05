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

    return Column(
      children: movements.map((m) {
        final sign = m.isIncome ? '+' : '-';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
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
                      formatDate(m.date),
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
                      // A transfer is neither income nor expense (see
                      // TransactionEntry.isTransfer): neutral color instead of
                      // authIncome/authExpense.
                      color: m.isTransfer
                          ? AppColors.authTransfer
                          : m.isIncome
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
