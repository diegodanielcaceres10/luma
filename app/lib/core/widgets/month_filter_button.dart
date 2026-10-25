import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../utils/app_clock.dart';

String formatMonthLabel(DateTime date) {
  final formatted = DateFormat('MMMM yyyy', 'es').format(date);
  return formatted[0].toUpperCase() + formatted.substring(1);
}

/// Shared month filter: a pill button showing the selected month that opens
/// a bottom sheet with the last 12 months.
///
/// Stateless: each screen owns the selected month and reacts to [onChanged].
class MonthFilterButton extends StatelessWidget {
  final DateTime selectedMonth;

  /// Called with the first day of the picked month; not called if the sheet
  /// is dismissed.
  final ValueChanged<DateTime> onChanged;

  const MonthFilterButton({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MonthPickerSheet(selectedMonth: selectedMonth),
    );

    if (picked != null && context.mounted) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authCardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: AppColors.authTextPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                formatMonthLabel(selectedMonth),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.authTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthPickerSheet extends StatelessWidget {
  final DateTime selectedMonth;

  const _MonthPickerSheet({required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final now = nowLocal();
    final currentMonth = DateTime(now.year, now.month);
    final months = List.generate(
      12,
      (i) => DateTime(currentMonth.year, currentMonth.month - i),
    );

    return SafeArea(
      top: false,
      // Cap the sheet height to avoid overflow on short screens.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.authCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Elegí un mes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: months.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final isSelected = month.year == selectedMonth.year &&
                        month.month == selectedMonth.month;

                    return Material(
                      color: isSelected
                          ? AppColors.authAccent.withValues(alpha: 0.12)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.authAccent.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(month),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                                color: isSelected
                                    ? AppColors.authAccent
                                    : AppColors.authTextSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  formatMonthLabel(month),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.authAccent
                                        : AppColors.authTextPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.authAccent,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
