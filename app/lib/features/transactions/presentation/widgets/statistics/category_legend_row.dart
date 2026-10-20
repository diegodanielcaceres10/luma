import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/category_visuals.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../view_models/transaction_view_model.dart';

/// Legend of a category donut chart. It is as wide as its longest row, so the
/// percentages stay in a column right next to the names instead of at the far
/// edge of the card.
class StatisticsCategoryLegend extends StatelessWidget {
  final List<CategoryTotal> breakdown;
  final String currency;

  /// Where the legend sits in the space it is given.
  final Alignment alignment;

  const StatisticsCategoryLegend({
    super.key,
    required this.breakdown,
    required this.currency,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    // The Align gives IntrinsicWidth loose constraints; under tight ones it
    // would still fill the whole width.
    return Align(
      alignment: alignment,
      child: IntrinsicWidth(
        child: Column(
          children: [
            for (final category in breakdown)
              StatisticsCategoryLegendRow(
                category: category,
                currency: currency,
              ),
          ],
        ),
      ),
    );
  }
}

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
          const SizedBox(width: 10),
          // Wide enough for "100%", so the column lines up across rows.
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Text(
              '${category.percent.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
