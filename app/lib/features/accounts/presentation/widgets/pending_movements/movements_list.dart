import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import 'pending_movement.dart';

class MovementsSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAddMovement;

  final bool enabled;

  const MovementsSectionHeader({
    super.key,
    required this.title,
    required this.onAddMovement,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: enabled ? onAddMovement : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.authAccent,
            side: const BorderSide(color: AppColors.authAccent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'Agregar movimiento',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class MovementsList extends StatelessWidget {
  final List<PendingMovement> movements;
  final String currency;
  final void Function(PendingMovement movement) onDelete;
  final void Function(PendingMovement movement) onEdit;

  final bool enabled;

  const MovementsList({
    super.key,
    required this.movements,
    required this.currency,
    required this.onDelete,
    required this.onEdit,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < movements.length; i++) ...[
            _MovementListTile(
              movement: movements[i],
              currency: currency,
              onDelete: enabled ? () => onDelete(movements[i]) : null,
              onEdit: enabled ? () => onEdit(movements[i]) : null,
            ),
            if (i < movements.length - 1)
              const Divider(color: AppColors.authCardBorder, height: 1),
          ],
        ],
      ),
    );
  }
}

class _MovementListTile extends StatelessWidget {
  final PendingMovement movement;
  final String currency;

  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _MovementListTile({
    required this.movement,
    required this.currency,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final amount = movement.amount;
    final amountText = amount > 0
        ? '+${formatCurrency(amount, currency)}'
        : formatCurrency(amount, currency);
    final amountColor =
        amount > 0 ? AppColors.authIncome : AppColors.authExpense;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextPrimary,
                  ),
                ),
                if (movement.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    movement.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  formatDate(movement.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.authTextSecondary,
            ),
            tooltip: 'Editar',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.authTextSecondary,
            ),
            tooltip: 'Quitar',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
