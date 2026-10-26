import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/category_visuals.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/widgets/cards/movement_tile.dart';
import 'pending_movement.dart';

/// A [PendingMovement] in the same row format as the movements history. The
/// date and the label (category, transfer or invoice) go on the second line,
/// so the first one is the description alone.
class PendingMovementTile extends StatelessWidget {
  final PendingMovement movement;
  final String currency;

  /// Row actions; the read-only recap has none.
  final Widget? trailing;

  const PendingMovementTile({
    super.key,
    required this.movement,
    required this.currency,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final amount = movement.amount;
    final formattedAmount = formatCurrency(amount, currency);

    // Without a category the line is just the date.
    final (leading, label) = switch (movement) {
      CategoryPendingMovement(:final category) => (
          category == null
              ? const MovementLeading.uncategorized()
              : MovementLeading.category(
                  color: colorFromHex(
                    category.color,
                    fallback: AppColors.authTextSecondary,
                  ),
                ),
          category?.name,
        ),
      TransferPendingMovement() => (
          const MovementLeading.transfer(),
          movement.displayLabel,
        ),
      InvoicePendingMovement() => (
          const MovementLeading.servicePayment(),
          movement.displayLabel,
        ),
    };

    return MovementTile(
      leading: leading,
      title: movement.description,
      subtitle: [formatDate(movement.date), if (label != null) label]
          .join(' · '),
      amountText: amount > 0 ? '+$formattedAmount' : formattedAmount,
      amountColor: amount > 0 ? AppColors.authIncome : AppColors.authExpense,
      trailing: trailing,
    );
  }
}
