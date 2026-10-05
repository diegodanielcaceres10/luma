import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/category_visuals.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../categories/data/models/category.dart';

class StatisticsBudgetProgress {
  final Category category;
  final double budgeted;
  final double spent;

  const StatisticsBudgetProgress({
    required this.category,
    required this.budgeted,
    required this.spent,
  });

  double get percent => budgeted > 0 ? (spent / budgeted) * 100 : 0.0;
  double get progress =>
      budgeted > 0 ? (spent / budgeted).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => percent > 100;
}

/// One progress bar per budgeted expense category. Current month only.
class StatisticsBudgetCategoriesCard extends StatelessWidget {
  final List<StatisticsBudgetProgress> items;
  final String currency;

  const StatisticsBudgetCategoriesCard({
    super.key,
    required this.items,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Presupuesto por categoría',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < items.length; i++) ...[
              _BudgetCategoryRow(item: items[i], currency: currency),
              if (i < items.length - 1) const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetCategoryRow extends StatelessWidget {
  final StatisticsBudgetProgress item;
  final String currency;

  const _BudgetCategoryRow({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final categoryColor =
        colorFromHex(category.color, fallback: AppColors.authAccent);
    final barColor = item.isOverBudget ? AppColors.authExpense : categoryColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatCurrency(item.budgeted, currency)} / mes',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.authTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.authCardBorder,
                  color: barColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(item.spent, currency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
