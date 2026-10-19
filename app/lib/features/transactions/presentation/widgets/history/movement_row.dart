import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/category_visuals.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/widgets/movement_tile.dart';
import '../../../data/models/transaction_entry.dart';

class TransactionMovementRow extends StatelessWidget {
  final TransactionEntry movement;
  final String currency;
  final bool showDivider;

  final bool isDeleting;

  final bool isUpdating;

  /// Whether the movement is the payment of a paid invoice. Shown with an
  /// icon, like transfers; the amount keeps the expense color because it
  /// still counts in the totals.
  final bool isServicePayment;

  /// Opens the movement actions menu (edit, transfer, invoice, delete).
  final VoidCallback? onActions;

  const TransactionMovementRow({
    super.key,
    required this.movement,
    required this.currency,
    required this.showDivider,
    this.isDeleting = false,
    this.isUpdating = false,
    this.isServicePayment = false,
    this.onActions,
  });

  @override
  Widget build(BuildContext context) {
    final sign = movement.isIncome ? '+' : '-';
    // Disable the menu while an action is running.
    final isBusy = isDeleting || isUpdating;

    // Transfers are neither income nor expense: use a neutral color.
    final amountColor = movement.isTransfer
        ? AppColors.authTransfer
        : movement.isIncome
            ? AppColors.authIncome
            : AppColors.authExpense;

    final MovementLeading leading;
    if (movement.isTransfer) {
      leading = const MovementLeading.transfer();
    } else if (isServicePayment) {
      leading = const MovementLeading.servicePayment();
    } else {
      leading = MovementLeading.category(
        color: colorFromHex(
          movement.category.color,
          fallback: AppColors.authTextSecondary,
        ),
      );
    }

    final categoryLabel =
        movement.isTransfer ? 'Transferencia' : movement.category.name;

    return Column(
      children: [
        MovementTile(
          leading: leading,
          title: movement.description,
          subtitle: '$categoryLabel · ${formatDate(movement.date)}',
          amountText: '$sign${formatCurrency(movement.amount, currency)}',
          amountColor: amountColor,
          trailing: onActions == null
              ? null
              : _RowActionButton(
                  icon: Icons.more_vert_rounded,
                  tooltip: 'Opciones del movimiento',
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onActions,
                ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}

class _RowActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _RowActionButton({
    required this.icon,
    required this.tooltip,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.authAccent,
                ),
              ),
            )
          : IconButton(
              padding: EdgeInsets.zero,
              iconSize: 20,
              splashRadius: 18,
              icon: Icon(icon, color: AppColors.authTextSecondary),
              tooltip: tooltip,
              onPressed: onPressed,
            ),
    );
  }
}
