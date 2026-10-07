import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../categories/data/models/category.dart';
import '../../../data/models/scanned_movement.dart';

class StatementReviewItem {
  ScannedMovement movement;
  Category? category;
  bool selected = false;
  bool inRange = true;
  bool duplicate = false;

  StatementReviewItem(this.movement);
}

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

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
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
                    item.category?.name == null
                        ? dateText
                        : '$dateText · ${item.category!.name}',
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
      ),
    );
  }
}
