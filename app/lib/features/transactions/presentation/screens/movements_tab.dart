import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/transaction_entry.dart';
import '../view_models/transaction_view_model.dart';

class MovementsTab extends StatelessWidget {
  final TransactionViewModel transactionViewModel;
  final String currency;

  const MovementsTab({
    super.key,
    required this.transactionViewModel,
    required this.currency,
  });

  Map<String, List<TransactionEntry>> _groupByMonth(
      List<TransactionEntry> transactions) {
    final monthFormat = DateFormat('MMMM yyyy', 'es');
    final Map<String, List<TransactionEntry>> grouped = {};

    for (final t in transactions) {
      final key = monthFormat.format(DateTime(t.date.year, t.date.month));
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: transactionViewModel,
        builder: (context, _) {
          final vm = transactionViewModel;

          if (vm.isLoadingAll && vm.allTransactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.allTransactions.isEmpty) {
            return RefreshIndicator(
              onRefresh: vm.loadAllTransactions,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Todavía no hay movimientos.',
                      style: AppTextStyles.subtitle,
                    ),
                  ),
                ],
              ),
            );
          }

          final grouped = _groupByMonth(vm.allTransactions);

          return RefreshIndicator(
            onRefresh: vm.loadAllTransactions,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Movimientos', style: AppTextStyles.title),
                const SizedBox(height: 20),
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Text(
                      _capitalize(entry.key),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: entry.value
                          .map((m) => _MovementRow(
                                movement: m,
                                currency: currency,
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

class _MovementRow extends StatelessWidget {
  final TransactionEntry movement;
  final String currency;

  const _MovementRow({required this.movement, required this.currency});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM. yyyy', 'es');
    final color = movement.isIncome
        ? AppColors.success
        : colorFromHex(movement.category.color, fallback: AppColors.primary);
    final sign = movement.isIncome ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(
              movement.isIncome
                  ? Icons.arrow_downward_rounded
                  : iconFromName(movement.category.icon),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description?.isNotEmpty == true
                      ? movement.description!
                      : movement.category.name,
                  style: AppTextStyles.body,
                ),
                Text(
                  '${movement.category.name} · ${dateFormat.format(movement.date)}',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$sign${formatCurrency(movement.amount, currency)}',
            style: AppTextStyles.body.copyWith(
              color: movement.isIncome ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
