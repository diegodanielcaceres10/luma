import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'closed_month_summary_card.dart';
import 'pending_movements_section.dart';

/// Last step of the closed-month justification: the movements loaded and the
/// summary of the month. The summary waits until every amount is known.
class ClosedMonthReviewStep extends StatelessWidget {
  final List<PendingMovement> movements;
  final double? openingBalance;
  final double? closingBalance;
  final double? difference;
  final double movementsTotal;
  final double? remainder;
  final String currency;

  /// Month in lowercase, as it reads inside a sentence.
  final String monthLabel;

  const ClosedMonthReviewStep({
    super.key,
    required this.movements,
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
    final opening = openingBalance;
    final closing = closingBalance;
    final difference = this.difference;
    final remainder = this.remainder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (movements.isNotEmpty) ...[
          const Text(
            'Movimientos cargados',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          PendingMovementsReadOnlyList(
            movements: movements,
            currency: currency,
          ),
          const SizedBox(height: 20),
        ],
        if (opening != null &&
            closing != null &&
            difference != null &&
            remainder != null)
          ClosedMonthSummaryCard(
            openingBalance: opening,
            closingBalance: closing,
            difference: difference,
            movementsTotal: movementsTotal,
            remainder: remainder,
            currency: currency,
            monthLabel: monthLabel,
          ),
      ],
    );
  }
}
