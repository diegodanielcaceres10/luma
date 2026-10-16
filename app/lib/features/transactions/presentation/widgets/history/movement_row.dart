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

  /// Icon that tells the movement kind apart, or null for regular ones.
  Icon? _kindIcon() {
    if (movement.isTransfer) {
      return const Icon(
        Icons.swap_horiz_rounded,
        size: 16,
        color: AppColors.authTransfer,
        semanticLabel: 'Transferencia',
      );
    }
    if (isServicePayment) {
      return const Icon(
        Icons.request_page_outlined,
        size: 16,
        color: AppColors.authInvoice,
        semanticLabel: 'Pago de servicio',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sign = movement.isIncome ? '+' : '-';
    // Disable the menu while an action is running.
    final isBusy = isDeleting || isUpdating;
    final kindIcon = _kindIcon();

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (kindIcon != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 6),
                            child: kindIcon,
                          ),
                        Expanded(
                          child: Text(
                            movement.description?.isNotEmpty == true
                                ? movement.description!
                                : movement.category.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.authTextPrimary,
                            ),
                          ),
                        ),
                      ],
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
              if (onActions != null) ...[
                const SizedBox(width: 4),
                _RowActionButton(
                  icon: Icons.more_vert,
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
