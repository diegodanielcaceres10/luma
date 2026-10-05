import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../data/models/transaction_entry.dart';

class TransactionMovementRow extends StatelessWidget {
  final TransactionEntry movement;
  final String currency;
  final bool showDivider;

  final bool isDeleting;

  final bool isUpdating;

  final VoidCallback? onEdit;

  final VoidCallback? onDelete;

  const TransactionMovementRow({
    super.key,
    required this.movement,
    required this.currency,
    required this.showDivider,
    this.isDeleting = false,
    this.isUpdating = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sign = movement.isIncome ? '+' : '-';
    // Disable both actions while either one is running.
    final isBusy = isDeleting || isUpdating;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.description?.isNotEmpty == true
                          ? movement.description!
                          : movement.category.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${movement.category.name} · ${formatDate(movement.date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign${formatCurrency(movement.amount, currency)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  // Transfers are neither income nor expense: use a neutral color.
                  color: movement.isTransfer
                      ? AppColors.authTransfer
                      : movement.isIncome
                          ? AppColors.authIncome
                          : AppColors.authExpense,
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 4),
                _RowActionButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Editar movimiento',
                  isLoading: isUpdating,
                  onPressed: isBusy ? null : onEdit,
                ),
              ],
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                _RowActionButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Eliminar movimiento',
                  isLoading: isDeleting,
                  onPressed: isBusy ? null : onDelete,
                ),
              ],
            ],
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
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.authTextSecondary,
                ),
              ),
            )
          : IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(icon, size: 20, color: AppColors.authTextSecondary),
              tooltip: tooltip,
              onPressed: onPressed,
            ),
    );
  }
}
