import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../view_models/month_comparison.dart';
import 'comparison_row_tile.dart';

const _monthAbbreviations = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

/// Three-letter month name, with the two-digit year when [withYear] is set
/// ("Dic 25"). Fixed list on purpose: it does not depend on locale data.
String shortMonthLabel(DateTime month, {required bool withYear}) {
  final name = _monthAbbreviations[month.month - 1];
  if (!withYear) return name;
  final year = (month.year % 100).toString().padLeft(2, '0');
  return '$name $year';
}

/// One block of the comparison (summary, categories or services): a title,
/// the column headers and a row per concept.
class ComparisonCard extends StatelessWidget {
  final String title;
  final DateTime beforeMonth;
  final DateTime afterMonth;
  final List<ComparisonRow> rows;
  final String currency;

  const ComparisonCard({
    super.key,
    required this.title,
    required this.beforeMonth,
    required this.afterMonth,
    required this.rows,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    // The year only shows when it tells the two months apart.
    final withYear = beforeMonth.year != afterMonth.year;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HeaderRow(
            beforeLabel: shortMonthLabel(beforeMonth, withYear: withYear),
            afterLabel: shortMonthLabel(afterMonth, withYear: withYear),
          ),
          const Divider(height: 12, color: AppColors.authCardBorder),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.authCardBorder),
            ComparisonRowTile(row: rows[i], currency: currency),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String beforeLabel;
  final String afterLabel;

  const _HeaderRow({required this.beforeLabel, required this.afterLabel});

  static const _style = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.authTextSecondary,
  );

  Widget _cell(int flex, String text) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: _style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(flex: comparisonConceptFlex),
        const SizedBox(width: comparisonColumnGap),
        _cell(comparisonAmountFlex, beforeLabel),
        const SizedBox(width: comparisonColumnGap),
        _cell(comparisonAmountFlex, afterLabel),
        const SizedBox(width: comparisonColumnGap),
        _cell(comparisonDeltaFlex, 'Δ'),
      ],
    );
  }
}
