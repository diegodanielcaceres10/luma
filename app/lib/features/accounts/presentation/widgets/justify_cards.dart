import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/secondary_button.dart';
import 'pending_movement_persistence.dart';

class NothingToJustifyCard extends StatelessWidget {
  final VoidCallback onBack;

  const NothingToJustifyCard({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.authAccent, size: 28),
          const SizedBox(height: 12),
          const Text(
            'No hay nada sin declarar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Esta cuenta no tiene saldo sin declarar este mes.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.authTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Volver',
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              padding: const EdgeInsets.symmetric(vertical: 14),
              borderRadius: 30,
              onPressed: onBack,
            ),
          ),
        ],
      ),
    );
  }
}

class JustifySummaryCard extends StatelessWidget {
  final double total;
  final double? remainder;
  final String currency;

  const JustifySummaryCard({
    super.key,
    required this.total,
    required this.remainder,
    required this.currency,
  });

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
      title = 'Cargando datos';
      message = 'Esperá a que termine de cargar el saldo sin declarar.';
    } else if (rem.abs() < kRemainderEpsilon) {
      tone = AppColors.authAccent;
      icon = Icons.check_rounded;
      title = 'Todo justificado';
      message = 'No va a quedar saldo sin declarar este mes en esta cuenta.';
    } else if (rem > 0) {
      tone = AppColors.authIncome;
      icon = Icons.priority_high_rounded;
      title = 'Justificación parcial';
      message = 'Van a quedar ${formatCurrency(rem, currency)} como ingreso '
          'sin declarar de este mes.';
    } else {
      tone = AppColors.authExpense;
      icon = Icons.priority_high_rounded;
      title = 'Justificación parcial';
      message = 'Van a quedar ${formatCurrency(rem.abs(), currency)} como '
          'gasto sin declarar de este mes.';
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
