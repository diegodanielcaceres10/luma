import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';

/// "Este mes: +12.300,00 USD" in green (up), red (down) or neutral (no
/// change), with a matching trend icon.
class MonthVariationIndicator extends StatelessWidget {
  final double variation;
  final String currency;

  const MonthVariationIndicator({
    super.key,
    required this.variation,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, sign) = variation > 0
        ? (AppColors.authIncome, Icons.trending_up_rounded, '+')
        : variation < 0
            ? (AppColors.authExpense, Icons.trending_down_rounded, '-')
            : (AppColors.authTextSecondary, Icons.trending_flat_rounded, '');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Este mes: $sign${formatCurrency(variation.abs(), currency)}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
