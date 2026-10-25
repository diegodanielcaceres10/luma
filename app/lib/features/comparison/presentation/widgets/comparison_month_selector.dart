import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/month_filter_button.dart';
import '../../../transactions/presentation/view_models/transactions_filters.dart';

/// Picks the two months to compare, one under the other: "Antes" on top,
/// "Después" below, with a button between them to swap them.
class ComparisonMonthSelector extends StatelessWidget {
  final DateTime before;
  final DateTime after;
  final ValueChanged<DateTime> onBeforeChanged;
  final ValueChanged<DateTime> onAfterChanged;
  final VoidCallback onSwap;

  const ComparisonMonthSelector({
    super.key,
    required this.before,
    required this.after,
    required this.onBeforeChanged,
    required this.onAfterChanged,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _MonthRow(
                  label: 'Antes',
                  month: before,
                  onChanged: onBeforeChanged,
                ),
                const SizedBox(height: 10),
                _MonthRow(
                  label: 'Después',
                  month: after,
                  onChanged: onAfterChanged,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Intercambiar meses',
            onPressed: onSwap,
            icon: const Icon(Icons.swap_vert_rounded),
            color: AppColors.authAccent,
          ),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final String label;
  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  const _MonthRow({
    required this.label,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // A Wrap, not a Row: on a narrow screen or with a large system font the
    // month button drops to its own line instead of overflowing.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
          MonthFilterButton(selectedMonth: month, onChanged: onChanged),
          if (TransactionsFilters.isCurrentMonth(month))
            const Text(
              'en curso',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.authTextSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
