import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../view_models/month_comparison.dart';

/// Column proportions shared by the card header and its rows so both line up.
const comparisonConceptFlex = 5;
const comparisonAmountFlex = 3;
const comparisonDeltaFlex = 3;
const comparisonColumnGap = 8.0;

const _noDataLabel = '—';
const _newLabel = 'Nuevo';

/// One concept of the comparison in columns: name, amount before, amount
/// after and the change.
class ComparisonRowTile extends StatelessWidget {
  final ComparisonRow row;
  final String currency;

  const ComparisonRowTile({
    super.key,
    required this.row,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: comparisonConceptFlex,
            child: _Concept(row: row, currency: currency),
          ),
          const SizedBox(width: comparisonColumnGap),
          Expanded(
            flex: comparisonAmountFlex,
            child: _Amount(value: row.before, currency: currency),
          ),
          const SizedBox(width: comparisonColumnGap),
          Expanded(
            flex: comparisonAmountFlex,
            child: _Amount(
              value: row.after,
              currency: currency,
              emphasized: true,
            ),
          ),
          const SizedBox(width: comparisonColumnGap),
          Expanded(
            flex: comparisonDeltaFlex,
            child: _Delta(row: row, currency: currency),
          ),
        ],
      ),
    );
  }
}

class _Concept extends StatelessWidget {
  final ComparisonRow row;
  final String currency;

  const _Concept({required this.row, required this.currency});

  @override
  Widget build(BuildContext context) {
    final colorHex = row.colorHex;
    final budget = row.budget;

    return Row(
      children: [
        if (colorHex != null) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorFromHex(colorHex, fallback: AppColors.authAccent),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              if (budget != null)
                Text(
                  'Presupuesto ${formatCurrency(budget, currency)} / mes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.authTextSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Amount extends StatelessWidget {
  final double? value;
  final String currency;
  final bool emphasized;

  const _Amount({
    required this.value,
    required this.currency,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final amount = value;

    // Long amounts shrink instead of wrapping or overflowing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        amount == null ? _noDataLabel : formatCurrency(amount, currency),
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          color: emphasized
              ? AppColors.authTextPrimary
              : AppColors.authTextSecondary,
        ),
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  final ComparisonRow row;
  final String currency;

  const _Delta({required this.row, required this.currency});

  Color get _color => switch (row.tone) {
        ComparisonTone.favorable => AppColors.authAccent,
        ComparisonTone.unfavorable => AppColors.authExpense,
        ComparisonTone.neutral => AppColors.authTextSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final difference = row.difference;
    final percent = row.percentChange;

    if (row.isNew) return _line(_newLabel, bold: true);
    if (difference == null) return _line(_noDataLabel, bold: true);

    final isFlat = difference.abs() < 0.005;
    if (isFlat && percent == null) return _line(_noDataLabel, bold: true);

    final differenceText = '${difference > 0 ? '+' : ''}'
        '${formatCurrency(difference, currency)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (percent != null) _line(_percentText(percent), bold: true),
        if (!isFlat) _line(differenceText, bold: false, small: true),
      ],
    );
  }

  /// Rounded first, so a tiny negative change reads "0%" and not "-0%".
  String _percentText(double percent) {
    final rounded = percent.round();
    return '${rounded > 0 ? '+' : ''}$rounded%';
  }

  Widget _line(String text, {required bool bold, bool small = false}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontSize: small ? 11 : 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: _color,
        ),
      ),
    );
  }
}
