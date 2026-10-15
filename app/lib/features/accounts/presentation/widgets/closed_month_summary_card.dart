import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import 'pending_movement_persistence.dart';

/// Last step of the closed-month justification: the balances typed, what the
/// movements cover and what will stay as the month's uncontrolled total.
class ClosedMonthSummaryCard extends StatelessWidget {
  final double openingBalance;
  final double closingBalance;
  final double difference;
  final double movementsTotal;
  final double remainder;
  final String currency;

  /// Month in lowercase, as it reads inside a sentence.
  final String monthLabel;

  const ClosedMonthSummaryCard({
    super.key,
    required this.openingBalance,
    required this.closingBalance,
    required this.difference,
    required this.movementsTotal,
    required this.remainder,
    required this.currency,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color tone;
    final IconData icon;
    final String title;
    final String message;

    if (remainder.abs() < kRemainderEpsilon) {
      tone = AppColors.authAccent;
      icon = Icons.check_rounded;
      title = 'Todo justificado';
      message = 'No va a quedar saldo sin declarar en $monthLabel.';
    } else if (remainder > 0) {
      tone = AppColors.authIncome;
      icon = Icons.priority_high_rounded;
      title = 'Justificación parcial';
      message = 'Van a quedar ${formatCurrency(remainder, currency)} como '
          'ingreso sin declarar de $monthLabel.';
    } else {
      tone = AppColors.authExpense;
      icon = Icons.priority_high_rounded;
      title = 'Justificación parcial';
      message = 'Van a quedar ${formatCurrency(remainder.abs(), currency)} '
          'como gasto sin declarar de $monthLabel.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: 'Saldo inicial',
            value: formatCurrency(openingBalance, currency),
          ),
          _SummaryRow(
            label: 'Saldo final',
            value: formatCurrency(closingBalance, currency),
          ),
          _SummaryRow(
            label: 'Diferencia',
            value: formatCurrency(difference, currency),
          ),
          _SummaryRow(
            label: 'Total de movimientos',
            value: formatCurrency(movementsTotal, currency),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tone.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: tone, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tone,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
