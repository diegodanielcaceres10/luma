import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

const trendValueStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: AppColors.authTextPrimary,
);

/// Card with a title, used by the "last 3 months" sections of the
/// category and service detail screens.
class TrendCard extends StatelessWidget {
  final String title;
  final Widget child;

  const TrendCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class TrendSummaryRow extends StatelessWidget {
  final String label;
  final Widget value;

  const TrendSummaryRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          value,
        ],
      ),
    );
  }
}

/// Percent change with an arrow. A null [percent] shows a dash.
class TrendChangeValue extends StatelessWidget {
  final double? percent;

  /// Whether an increase is good news (income) or bad news (spending).
  final bool risingIsGood;

  const TrendChangeValue({
    super.key,
    required this.percent,
    required this.risingIsGood,
  });

  @override
  Widget build(BuildContext context) {
    final value = percent;
    if (value == null) return const Text('—', style: trendValueStyle);

    final rounded = value.round();
    if (rounded == 0) return const Text('0%', style: trendValueStyle);

    final rising = rounded > 0;
    final good = rising == risingIsGood;
    final color = good ? AppColors.authIncome : AppColors.authExpense;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          rising ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${rounded.abs()}%',
          style: trendValueStyle.copyWith(color: color),
        ),
      ],
    );
  }
}
