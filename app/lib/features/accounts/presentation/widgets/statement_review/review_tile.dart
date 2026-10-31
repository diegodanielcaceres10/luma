import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/widgets/cards/movement_tile.dart';
import '../../../data/models/scanned_movement.dart';

class StatementReviewItem {
  ScannedMovement movement;
  bool selected = false;
  bool inRange = true;
  bool duplicate = false;

  StatementReviewItem(this.movement);
}

/// A line read from a statement, in the same row format as the movements
/// history. It has no category: that is chosen after the line is added.
class StatementReviewTile extends StatelessWidget {
  final StatementReviewItem item;
  final String currency;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onEdit;

  const StatementReviewTile({
    super.key,
    required this.item,
    required this.currency,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final movement = item.movement;
    final amount = movement.signedAmount;
    final amountText = amount > 0
        ? '+${formatCurrency(amount, currency)}'
        : formatCurrency(amount, currency);

    final date = movement.date;

    String? warning;
    if (!item.inRange) {
      warning = 'Fuera del período';
    } else if (item.duplicate) {
      warning = 'Posible duplicado';
    }

    // A line outside the period can't be added, so there is nothing to fix.
    return InkWell(
      onTap: item.inRange ? onEdit : null,
      child: MovementTile(
        padding: const EdgeInsets.symmetric(vertical: 8),
        leading: Checkbox(
          value: item.selected,
          activeColor: AppColors.authAccent,
          checkColor: AppColors.authBackgroundBottom,
          side: const BorderSide(color: AppColors.authTextSecondary),
          onChanged: item.inRange ? onToggle : null,
        ),
        title: movement.description,
        subtitle: date == null ? 'Sin fecha' : formatDate(date),
        warning: warning,
        amountText: amountText,
        amountColor: amount > 0 ? AppColors.authIncome : AppColors.authExpense,
      ),
    );
  }
}
