import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import 'pending_movement_persistence.dart';

class OpeningSummaryCard extends StatelessWidget {
  final double previousBalance;
  final double openingBalance;
  final double difference;
  final double movementsTotal;
  final double remainder;
  final String currency;
  final String openingMonthLabel;
  final String previousMonthLabel;

  const OpeningSummaryCard({
    super.key,
    required this.previousBalance,
    required this.openingBalance,
    required this.difference,
    required this.movementsTotal,
    required this.remainder,
    required this.currency,
    required this.openingMonthLabel,
    required this.previousMonthLabel,
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
      title = 'Coincide con la diferencia';
      message = 'No hace falta ningún ajuste. Se registra el saldo inicial '
          'de $openingMonthLabel.';
    } else if (remainder > 0) {
      tone = AppColors.authIncome;
      icon = Icons.priority_high_rounded;
      title = 'Diferencia sin justificar';
      message = 'Se sumarán ${formatCurrency(remainder, currency)} como '
          'ingreso no controlado de $previousMonthLabel, sin registrar un '
          'movimiento.';
    } else {
      tone = AppColors.authExpense;
      icon = Icons.priority_high_rounded;
      title = 'Diferencia sin justificar';
      message = 'Se sumarán ${formatCurrency(remainder.abs(), currency)} como '
          'gasto no controlado de $previousMonthLabel, sin registrar un '
          'movimiento.';
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
            label: 'Saldo anterior',
            value: formatCurrency(previousBalance, currency),
          ),
          _SummaryRow(
            label: 'Saldo inicial de $openingMonthLabel',
            value: formatCurrency(openingBalance, currency),
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
