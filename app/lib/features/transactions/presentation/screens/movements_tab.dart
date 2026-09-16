import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/transaction_entry.dart';
import '../view_models/transaction_view_model.dart';

/// Contenido de la pestaña "Movimientos". No tiene Scaffold propio — vive
/// dentro del Scaffold del HomeShell, que es quien pone el header y el
/// bottomNavigationBar.
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.authAccent),
            );
          }

          if (vm.allTransactions.isEmpty) {
            return RefreshIndicator(
              onRefresh: vm.loadAllTransactions,
              color: AppColors.authAccent,
              backgroundColor: AppColors.authBackgroundTop,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Todavía no hay movimientos.',
                      style: AppTextStyles.authSubtitle,
                    ),
                  ),
                ],
              ),
            );
          }

          final grouped = _groupByMonth(vm.allTransactions);

          return RefreshIndicator(
            onRefresh: vm.loadAllTransactions,
            color: AppColors.authAccent,
            backgroundColor: AppColors.authBackgroundTop,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const Text(
                  'Movimientos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Text(
                      _capitalize(entry.key),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                    child: Column(
                      children: List.generate(entry.value.length, (i) {
                        return _MovementRow(
                          movement: entry.value[i],
                          currency: currency,
                          showDivider: i != entry.value.length - 1,
                        );
                      }),
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
  final bool showDivider;

  const _MovementRow({
    required this.movement,
    required this.currency,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM. yyyy', 'es');
    final color = movement.isIncome
        ? AppColors.authIncome
        : colorFromHex(movement.category.color, fallback: AppColors.authAccent);
    final sign = movement.isIncome ? '+' : '-';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.85),
                child: Icon(
                  movement.isIncome
                      ? Icons.arrow_downward_rounded
                      : iconFromName(movement.category.icon),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${movement.category.name} · ${dateFormat.format(movement.date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign${formatCurrency(movement.amount, currency)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      movement.isIncome ? AppColors.authIncome : AppColors.authExpense,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}
