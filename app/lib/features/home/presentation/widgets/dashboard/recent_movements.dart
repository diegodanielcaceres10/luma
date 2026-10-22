import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_text_styles.dart';
import '../../../../transactions/data/models/transaction_entry.dart';
import '../../../../transactions/presentation/widgets/history/movement_row.dart';

class DashboardRecentMovements extends StatelessWidget {
  final bool isLoading;
  final List<TransactionEntry> movements;
  final String currency;

  /// Ids of the movements that are the payment of a paid invoice.
  final Set<String> servicePaymentIds;

  const DashboardRecentMovements({
    super.key,
    required this.isLoading,
    required this.movements,
    required this.currency,
    this.servicePaymentIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.authCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.authCardBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.authAccent,
            ),
          ),
        ),
      );
    }

    if (movements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.authCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.authCardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.authTextSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Todavía no hay movimientos este mes.',
              textAlign: TextAlign.center,
              style: AppTextStyles.authSubtitle,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < movements.length; i++)
            TransactionMovementRow(
              movement: movements[i],
              currency: currency,
              showDivider: i < movements.length - 1,
              isServicePayment: servicePaymentIds.contains(movements[i].id),
            ),
        ],
      ),
    );
  }
}
