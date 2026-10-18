import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';

/// Signed sum of uncontrolled adjustments for the month (negative is an
/// expense). Only shown when non-zero.
class StatisticsUncontrolledCard extends StatelessWidget {
  final double total;
  final String currency;

  const StatisticsUncontrolledCard({
    super.key,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = total < 0;
    final tone = isExpense ? AppColors.authExpense : AppColors.authIncome;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tone.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.priority_high_rounded,
                  size: 20,
                  color: tone,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sin declarar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isExpense
                        ? 'Gasto no controlado este mes'
                        : 'Ingreso no controlado este mes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.authTextFooter,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(total.abs(), currency),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
