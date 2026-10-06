import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import 'pending_movement_persistence.dart';

class MovementsSummaryCard extends StatelessWidget {
  final double total;

  final double? remainder;
  final String currency;

  const MovementsSummaryCard({
    super.key,
    required this.total,
    required this.remainder,
    required this.currency,
  });

  static const _epsilon = kRemainderEpsilon;

  @override
  Widget build(BuildContext context) {
    final rem = remainder;

    final Color tone;
    final IconData icon;
    final String title;
    final String message;

    if (rem == null) {
      tone = AppColors.authTextSecondary;
      icon = Icons.info_outline_rounded;
      title = 'Falta el saldo nuevo';
      message = 'Ingresa el nuevo saldo para calcular la diferencia.';
    } else if (rem.abs() < _epsilon) {
      tone = AppColors.authAccent;
      icon = Icons.check_rounded;
      title = 'Coincide con la diferencia';
      message = 'El saldo se actualiza correctamente.';
    } else if (rem > 0) {
      tone = AppColors.authIncome;
      icon = Icons.priority_high_rounded;
      title = 'Diferencia sin justificar';
      message = 'Se ajustará el balance por '
          '${formatCurrency(rem, currency)} como ingreso no controlado, '
          'sin registrar un movimiento.';
    } else {
      tone = AppColors.authExpense;
      icon = Icons.priority_high_rounded;
      title = 'Diferencia sin justificar';
      message = 'Se ajustará el balance por '
          '${formatCurrency(rem.abs(), currency)} como gasto no '
          'controlado, sin registrar un movimiento.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.authAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calculate_rounded,
                    color: AppColors.authAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total de movimientos',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatCurrency(total, currency),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.authTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.authCardBorder,
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tone, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tone,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
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
