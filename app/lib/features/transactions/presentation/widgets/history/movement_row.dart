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

    final color = movement.isTransfer
        ? AppColors.authTransfer
        : movement.isIncome
            ? AppColors.authIncome
            : AppColors.authExpense;

    final IconData iconData;
    final String? semanticLabel;
    if (movement.isTransfer) {
      iconData = Icons.swap_horiz_rounded;
      semanticLabel = 'Transferencia';
    } else if (isServicePayment) {
      iconData = Icons.request_page_outlined;
      semanticLabel = 'Pago de servicio';
    } else if (movement.isIncome) {
      iconData = Icons.arrow_downward_rounded;
      semanticLabel = null;
    } else {
      iconData = Icons.arrow_upward_rounded;
      semanticLabel = null;
    }

    final podColor = isServicePayment ? AppColors.authInvoice : color;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: podColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: podColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: podColor,
                    size: 20,
                    semanticLabel: semanticLabel,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.description?.isNotEmpty == true
                          ? movement.description!
                          : movement.category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.authTextPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${movement.category.name} · ${formatDate(movement.date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign${formatCurrency(movement.amount, currency)}',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  // Transfers are neither income nor expense: use a neutral color.
                  color: color,
                ),
              ),
              if (onActions != null) ...[
                const SizedBox(width: 4),
                _RowActionButton(
                  icon: Icons.more_vert_rounded,
                  tooltip: 'Opciones del movimiento',
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onActions,
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
