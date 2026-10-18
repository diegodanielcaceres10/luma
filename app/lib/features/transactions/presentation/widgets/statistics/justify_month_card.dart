import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/secondary_button.dart';

/// Offers to justify a past month for the accounts that were left without
/// loading (no opening balance and no movements in it).
class StatisticsJustifyMonthCard extends StatelessWidget {
  /// Month in lowercase, as it reads inside a sentence.
  final String monthLabel;
  final List<String> accountNames;
  final VoidCallback onPressed;

  const StatisticsJustifyMonthCard({
    super.key,
    required this.monthLabel,
    required this.accountNames,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.authAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.authAccent.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.edit_calendar_rounded,
                  size: 20,
                  color: AppColors.authAccent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sin cargar en $monthLabel',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    accountNames.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.authTextFooter,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SecondaryButton(
              label: 'Justificar',
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              borderRadius: 30,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
