import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../view_models/transaction_view_model.dart';

class StatisticsTab extends StatelessWidget {
  final TransactionViewModel transactionViewModel;
  final String currency;

  const StatisticsTab({
    super.key,
    required this.transactionViewModel,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: transactionViewModel,
      builder: (context, _) {
        final vm = transactionViewModel;

        if (vm.isLoading && vm.categoryBreakdown.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.authAccent),
          );
        }

        final breakdown = vm.categoryBreakdown;

        if (breakdown.isEmpty) {
          return const Center(
            child: Text(
              'Todavía no hay gastos este mes.',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const Text(
              'Gastos por categoría',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(vm.totalExpenses, currency),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const Text(
              'gastados este mes',
              style: TextStyle(fontSize: 12, color: AppColors.authTextFooter),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.authCardFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.authCardBorder),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: breakdown
                      .map((c) => _CategoryBar(
                            category: c,
                            currency: currency,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final CategoryTotal category;
  final String currency;

  const _CategoryBar({required this.category, required this.currency});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.authAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.85),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.category.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextPrimary,
                  ),
                ),
              ),
              Text(
                formatCurrency(category.amount, currency),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${category.percent.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (category.percent / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.authBackgroundTop,
              valueColor: const AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
