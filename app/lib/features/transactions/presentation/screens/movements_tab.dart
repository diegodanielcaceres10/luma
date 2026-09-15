import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
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
    return ListenableBuilder(
      listenable: transactionViewModel,
      builder: (context, _) {
        final vm = transactionViewModel;

        if (vm.isLoadingAll && vm.allTransactions.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.authAccent),
          );
        }

        if (vm.allTransactions.isEmpty) {
          return RefreshIndicator(
            color: AppColors.authAccent,
            backgroundColor: AppColors.authBackgroundBottom,
            onRefresh: vm.loadAllTransactions,
            child: ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'Todavía no hay movimientos.',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                ),
              ],
            ),
          );
        }

        final grouped = _groupByMonth(vm.allTransactions);

        return RefreshIndicator(
          color: AppColors.authAccent,
          backgroundColor: AppColors.authBackgroundBottom,
          onRefresh: vm.loadAllTransactions,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(
                    _capitalize(entry.key),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.authCardFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.authCardBorder),
                  ),
                  child: Padding(
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
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        );
      },
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
    final dateFormat = DateFormat('d MMM yyyy', 'es');
    final color = movement.isIncome
        ? AppColors.authIncome
        : colorFromHex(movement.category.color, fallback: AppColors.authExpense);
    final sign = movement.isIncome ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.85),
            child: Icon(
              movement.isIncome
                  ? Icons.arrow_downward_rounded
                  : iconFromName(movement.category.icon),
              color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.authTextPrimary,
                  ),
                ),
                Text(
                  dateFormat.format(movement.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${formatCurrency(movement.amount, currency)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: movement.isIncome
                      ? AppColors.authIncome
                      : AppColors.authExpense,
                ),
              ),
              Text(
                movement.isIncome ? 'Ingreso' : movement.category.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.authTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
