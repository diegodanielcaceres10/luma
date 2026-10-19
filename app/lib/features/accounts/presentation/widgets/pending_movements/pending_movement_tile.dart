import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/category_visuals.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/widgets/movement_tile.dart';
import 'pending_movement.dart';

/// A [PendingMovement] in the same row format as the movements history. The
/// label (category, transfer or invoice) goes on the second line, so the first
/// one is the description alone.
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

    final leading = switch (movement) {
      CategoryPendingMovement(:final category) => MovementLeading.category(
          color: colorFromHex(
            category?.color,
            fallback: AppColors.authTextSecondary,
          ),
        ),
      TransferPendingMovement() => const MovementLeading.transfer(),
      InvoicePendingMovement() => const MovementLeading.servicePayment(),
    };

    return MovementTile(
      leading: leading,
      title: movement.description,
      subtitle: '${movement.displayLabel} · ${formatDate(movement.date)}',
      amountText: amount > 0 ? '+$formattedAmount' : formattedAmount,
      amountColor: amount > 0 ? AppColors.authIncome : AppColors.authExpense,
      trailing: trailing,
    );
  }
}
