import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/category_visuals.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../view_models/transaction_view_model.dart';

class StatisticsCategoryLegendRow extends StatelessWidget {
  final CategoryTotal category;
  final String currency;

  const StatisticsCategoryLegendRow({
    super.key,
    required this.category,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    // Uncategorized has no color: keep the dot transparent.
    final color =
        colorFromHex(category.category.color, fallback: Colors.transparent);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          // The amount sits under the name so a long amount never squeezes
          // the name on narrow screens.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(category.amount, currency),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: Text(
              '${category.percent.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
