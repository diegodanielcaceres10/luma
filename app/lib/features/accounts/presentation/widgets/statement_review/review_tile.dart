import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../data/models/scanned_movement.dart';

class StatementReviewItem {
  ScannedMovement movement;
  bool selected = false;
  bool inRange = true;
  bool duplicate = false;

  /// The description mentions a transfer.
  bool isTransfer = false;

  /// While [isTransfer], whether the line is added as a transfer; the user
  /// can untick it to add it as a regular movement.
  bool asTransfer = false;

  StatementReviewItem(this.movement);
}

class StatementReviewTile extends StatelessWidget {
  final StatementReviewItem item;
  final String currency;
  final ValueChanged<bool?> onToggle;
  final ValueChanged<bool?> onToggleTransfer;
  final VoidCallback onEdit;

  const StatementReviewTile({
    super.key,
    required this.item,
    required this.currency,
    required this.onToggle,
    required this.onToggleTransfer,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final movement = item.movement;
    final amount = movement.signedAmount;
    final amountText = amount > 0
        ? '+${formatCurrency(amount, currency)}'
        : formatCurrency(amount, currency);
    final amountColor =
        amount > 0 ? AppColors.authIncome : AppColors.authExpense;

    final date = movement.date;
    final dateText = date == null ? 'Sin fecha' : formatDate(date);

    String? warning;
    if (!item.inRange) {
      warning = 'Fuera del período';
    } else if (item.duplicate) {
      warning = 'Posible duplicado';
    }

    // A line outside the period can't be added, so the alert would be moot.
    final showTransferAlert = item.isTransfer && item.inRange;

    // A line outside the period can't be added, so there is nothing to fix.
    return InkWell(
      onTap: item.inRange ? onEdit : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: item.selected,
                  activeColor: AppColors.authAccent,
                  checkColor: AppColors.authBackgroundBottom,
                  side: const BorderSide(color: AppColors.authTextSecondary),
                  onChanged: item.inRange ? onToggle : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.description ?? 'Sin descripción',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.authTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                      if (warning != null)
                        Text(
                          warning,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.authExpense,
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
                const SizedBox(width: 4),
              ],
            ),
            if (showTransferAlert)
              _TransferAlert(item: item, onChanged: onToggleTransfer),
          ],
        ),
      ),
    );
  }
}

/// Warns that the line looks like a transfer between own accounts, which is
/// added as a transfer unless the user unticks the box.
class _TransferAlert extends StatelessWidget {
  final StatementReviewItem item;
  final ValueChanged<bool?> onChanged;

  const _TransferAlert({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.authAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.authCardBorder),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parece una transferencia entre cuentas. No cuenta como '
              'ingreso ni gasto.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.authTextPrimary,
              ),
            ),
            CheckboxListTile(
              value: item.asTransfer,
              onChanged: onChanged,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.authAccent,
              checkColor: AppColors.authBackgroundBottom,
              side: const BorderSide(color: AppColors.authTextSecondary),
              title: const Text(
                'Registrar como transferencia',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
