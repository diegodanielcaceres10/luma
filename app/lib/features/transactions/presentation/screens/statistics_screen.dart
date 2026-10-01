import 'dart:math';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/month_filter_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/transaction_entry.dart' show TransactionCategory;
import '../export/statistics_pdf_builder.dart';
import '../view_models/transaction_view_model.dart';

class StatisticsScreen extends StatefulWidget {
  final TransactionViewModel transactionViewModel;

  final CategoryViewModel categoryViewModel;
  final String currency;

  const StatisticsScreen({
    super.key,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.currency,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isExportingPdf = false;

  /// Generates the month's PDF and downloads it (web) or opens the share
  /// sheet (mobile). Only offered for closed months.
  Future<void> _exportPdf() async {
    if (_isExportingPdf) return;

    // Snapshot before the first await so the PDF matches the month where the
    // user tapped, even if they switch months while it generates.
    final vm = widget.transactionViewModel;
    final data = StatisticsPdfData(
      month: vm.statisticsMonth,
      monthLabel: formatMonthLabel(vm.statisticsMonth),
      currency: widget.currency,
      income: vm.statisticsIncome,
      expenses: vm.statisticsExpenses,
      netResult: vm.statisticsNetResult,
      incomeChangePercent: vm.statisticsIncomeChangePercent,
      expenseChangePercent: vm.statisticsExpenseChangePercent,
      netChangePercent: vm.statisticsNetResultChangePercent,
      breakdown: List.of(vm.statisticsCategoryBreakdown),
      uncontrolledTotal: vm.statisticsUncontrolledTotal,
    );

    setState(() => _isExportingPdf = true);
    try {
      final bytes = await StatisticsPdfBuilder.build(data);
      await Printing.sharePdf(bytes: bytes, filename: data.fileName);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  List<_BudgetProgress> get _budgetProgress {
    final spentByCategoryId = <String, double>{
      for (final total
          in widget.transactionViewModel.statisticsCategoryBreakdown)
        if (total.category.id != null) total.category.id!: total.amount,
    };

    return widget.categoryViewModel.budgetedCategories
        .map((category) => _BudgetProgress(
              category: category,
              budgeted: category.budgetAmount ?? 0,
              spent: spentByCategoryId[category.id] ?? 0,
            ))
        .toList();
  }

  /// Splits the month's expenses into categorized, uncategorized and
  /// uncontrolled-adjustment buckets, skipping empty ones.
  List<CategoryTotal> _expenseTypeBreakdown(TransactionViewModel vm) {
    final breakdown = vm.statisticsCategoryBreakdown;
    final categorized = breakdown
        .where((c) => c.category.id != null)
        .fold<double>(0, (sum, c) => sum + c.amount);
    final uncategorized = breakdown
        .where((c) => c.category.id == null)
        .fold<double>(0, (sum, c) => sum + c.amount);
    final undeclared = vm.statisticsUncontrolledTotal < 0
        ? -vm.statisticsUncontrolledTotal
        : 0.0;

    final total = categorized + uncategorized + undeclared;
    double percentOf(double amount) => total > 0 ? (amount / total) * 100 : 0;

    return [
      if (categorized > 0)
        CategoryTotal(
          category: const TransactionCategory(
            name: 'Categorizados',
            color: '#4CBB7A',
          ),
          amount: categorized,
          percent: percentOf(categorized),
        ),
      if (uncategorized > 0)
        CategoryTotal(
          category: const TransactionCategory(
            name: 'No categorizados',
            color: '#F59E0B',
          ),
          amount: uncategorized,
          percent: percentOf(uncategorized),
        ),
      if (undeclared > 0)
        CategoryTotal(
          category: const TransactionCategory(
            name: 'No declarados',
            color: '#EF6F5B',
          ),
          amount: undeclared,
          percent: percentOf(undeclared),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        [widget.transactionViewModel, widget.categoryViewModel],
      ),
      builder: (context, _) {
        final vm = widget.transactionViewModel;
        final month = vm.statisticsMonth;
        final isCurrentMonth = vm.isStatisticsCurrentMonth;
        final monthInSentence = formatMonthLabel(month).toLowerCase();

        // The PDF is only offered for closed months with data.
        final canExportPdf = !isCurrentMonth &&
            !vm.isStatisticsLoading &&
            vm.statisticsErrorMessage == null &&
            (vm.statisticsIncome > 0 || vm.statisticsExpenses > 0);

        final header = _StatisticsHeader(
          selectedMonth: month,
          onMonthChanged: vm.loadStatisticsMonth,
          onExportPdf: canExportPdf ? _exportPdf : null,
          isExportingPdf: _isExportingPdf,
        );

        // Budgets track the current month only.
        final budgetProgress =
            isCurrentMonth ? _budgetProgress : const <_BudgetProgress>[];
        final budgetCard = budgetProgress.isEmpty
            ? null
            : _BudgetCategoriesCard(
                items: budgetProgress,
                currency: widget.currency,
              );

        final uncontrolledCard = !vm.statisticsHasUncontrolledTotal
            ? null
            : _UncontrolledCard(
                total: vm.statisticsUncontrolledTotal,
                currency: widget.currency,
              );

        // The month in progress isn't comparable with a full previous month,
        // so the change vs. the previous month is only shown for past months.
        final incomeChangePercent =
            isCurrentMonth ? null : vm.statisticsIncomeChangePercent;
        final expenseChangePercent =
            isCurrentMonth ? null : vm.statisticsExpenseChangePercent;
        final netChangePercent =
            isCurrentMonth ? null : vm.statisticsNetResultChangePercent;

        final breakdown = vm.statisticsCategoryBreakdown;
        // Uncategorized entries appear in the breakdown below, not in this chart.
        final categorizedTotal = breakdown
            .where((c) => c.category.id != null)
            .fold<double>(0, (sum, c) => sum + c.amount);
        // Recalculated against categorizedTotal so the donut and legend sum to
        // 100%.
        final categorizedBreakdown = breakdown
            .where((c) => c.category.id != null)
            .map((c) => CategoryTotal(
                  category: c.category,
                  amount: c.amount,
                  percent: categorizedTotal > 0
                      ? (c.amount / categorizedTotal) * 100
                      : 0,
                ))
            .toList();
        final expenseTypeBreakdown = _expenseTypeBreakdown(vm);
        final expenseTypeTotal =
            expenseTypeBreakdown.fold<double>(0, (sum, c) => sum + c.amount);

        // Expenses and balance include the uncontrolled adjustment; a positive
        // one (income) only affects the balance.
        final uncontrolledExpensePart = vm.statisticsUncontrolledTotal < 0
            ? -vm.statisticsUncontrolledTotal
            : 0.0;
        final statisticsExpensesTotal =
            vm.statisticsExpenses + uncontrolledExpensePart;
        final statisticsNetResultTotal =
            vm.statisticsNetResult + vm.statisticsUncontrolledTotal;

        if (vm.isStatisticsLoading && breakdown.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              header,
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.authAccent),
                ),
              ),
            ],
          );
        }

        final errorMessage = vm.statisticsErrorMessage;
        if (errorMessage != null && breakdown.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              header,
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.authAccent,
                      ),
                      onPressed: () => vm.loadStatisticsMonth(month),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (breakdown.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              header,
              const SizedBox(height: 20),
              _SummaryCardsRow(
                income: vm.statisticsIncome,
                expenses: statisticsExpensesTotal,
                netResult: statisticsNetResultTotal,
                incomeChangePercent: incomeChangePercent,
                expenseChangePercent: expenseChangePercent,
                netChangePercent: netChangePercent,
                currency: widget.currency,
              ),
              if (uncontrolledCard != null) ...[
                const SizedBox(height: 10),
                uncontrolledCard,
              ],
              if (budgetCard != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Presupuesto',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                budgetCard,
              ],
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    isCurrentMonth
                        ? 'Todavía no hay gastos este mes.'
                        : 'No hay gastos registrados en $monthInSentence.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.authTextSecondary),
                  ),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            header,
            const SizedBox(height: 20),
            _SummaryCardsRow(
              income: vm.statisticsIncome,
              expenses: statisticsExpensesTotal,
              netResult: statisticsNetResultTotal,
              incomeChangePercent: incomeChangePercent,
              expenseChangePercent: expenseChangePercent,
              netChangePercent: netChangePercent,
              currency: widget.currency,
            ),
            if (uncontrolledCard != null) ...[
              const SizedBox(height: 10),
              uncontrolledCard,
            ],
            if (budgetCard != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Presupuesto',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              budgetCard,
            ],
            const SizedBox(height: 24),
            if (expenseTypeBreakdown.isNotEmpty) ...[
              const Text(
                'Categorizado, sin categoría y no declarado',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency(expenseTypeTotal, widget.currency),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              Text(
                isCurrentMonth
                    ? 'gastados este mes'
                    : 'gastados en $monthInSentence',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.authTextFooter,
                ),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.authCardFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.authCardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _CategoryDonutChart(
                        breakdown: expenseTypeBreakdown,
                        total: expenseTypeTotal,
                        currency: widget.currency,
                        label: 'Gasto real',
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: expenseTypeBreakdown
                              .map((c) => _CategoryLegendRow(
                                    category: c,
                                    currency: widget.currency,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (categorizedBreakdown.isNotEmpty) ...[
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
                formatCurrency(categorizedTotal, widget.currency),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              Text(
                isCurrentMonth
                    ? 'gastados este mes'
                    : 'gastados en $monthInSentence',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.authTextFooter,
                ),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.authCardFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.authCardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _CategoryDonutChart(
                        breakdown: categorizedBreakdown,
                        total: categorizedTotal,
                        currency: widget.currency,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: categorizedBreakdown
                              .map((c) => _CategoryLegendRow(
                                    category: c,
                                    currency: widget.currency,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatisticsHeader extends StatelessWidget {
  final DateTime selectedMonth;

  final ValueChanged<DateTime> onMonthChanged;

  /// Null hides the "Exportar PDF" button.
  final VoidCallback? onExportPdf;
  final bool isExportingPdf;

  const _StatisticsHeader({
    required this.selectedMonth,
    required this.onMonthChanged,
    this.onExportPdf,
    this.isExportingPdf = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenHeader(
          title: 'Estadísticas',
          subtitle:
              'Analiza tus ingresos, gastos y mantén el control de tus finanzas.',
          action: MonthFilterButton(
            selectedMonth: selectedMonth,
            onChanged: onMonthChanged,
          ),
        ),
        if (onExportPdf != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.authAccent,
              side: const BorderSide(color: AppColors.authCardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: isExportingPdf ? null : onExportPdf,
            icon: isExportingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.authAccent,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(isExportingPdf ? 'Generando…' : 'Exportar PDF'),
          ),
        ],
      ],
    );
  }
}

class _SummaryCardsRow extends StatelessWidget {
  final double income;
  final double expenses;
  final double netResult;
  final double? incomeChangePercent;
  final double? expenseChangePercent;
  final double? netChangePercent;
  final String currency;

  const _SummaryCardsRow({
    required this.income,
    required this.expenses,
    required this.netResult,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
    required this.netChangePercent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.arrow_downward_rounded,
            iconBackground: AppColors.authIncome,
            label: 'Ingresos',
            amount: income,
            changePercent: incomeChangePercent,
            isFavorable:
                incomeChangePercent == null ? null : incomeChangePercent! >= 0,
            currency: currency,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.arrow_upward_rounded,
            iconBackground: AppColors.authExpense,
            label: 'Gastos',
            amount: expenses,
            changePercent: expenseChangePercent,
            // For expenses, spending less than last month is the improvement.
            isFavorable: expenseChangePercent == null
                ? null
                : expenseChangePercent! <= 0,
            currency: currency,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBackground: AppColors.authAccentDark,
            label: 'Balance del mes',
            amount: netResult,
            changePercent: netChangePercent,
            isFavorable:
                netChangePercent == null ? null : netChangePercent! >= 0,
            currency: currency,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String label;
  final double amount;
  final double? changePercent;
  final bool? isFavorable;
  final String currency;

  const _SummaryCard({
    required this.icon,
    required this.iconBackground,
    required this.label,
    required this.amount,
    required this.changePercent,
    required this.isFavorable,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconBackground,
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.authTextSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatCurrency(amount, currency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            if (changePercent != null && isFavorable != null) ...[
              const SizedBox(height: 6),
              _ChangeIndicator(
                changePercent: changePercent!,
                isFavorable: isFavorable!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows the change vs. the previous month with an arrow and a color that
/// depends on [isFavorable]; for expenses, decreasing is favorable.
class _ChangeIndicator extends StatelessWidget {
  final double changePercent;
  final bool isFavorable;

  const _ChangeIndicator({
    required this.changePercent,
    required this.isFavorable,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFavorable ? AppColors.authAccent : AppColors.authExpense;
    final icon = changePercent >= 0
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final sign = changePercent > 0 ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '$sign${changePercent.toStringAsFixed(0)}% vs. mes anterior',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetProgress {
  final Category category;
  final double budgeted;
  final double spent;

  const _BudgetProgress({
    required this.category,
    required this.budgeted,
    required this.spent,
  });

  double get percent => budgeted > 0 ? (spent / budgeted) * 100 : 0.0;
  double get progress =>
      budgeted > 0 ? (spent / budgeted).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => percent > 100;
}

/// One progress bar per budgeted expense category. Current month only.
class _BudgetCategoriesCard extends StatelessWidget {
  final List<_BudgetProgress> items;
  final String currency;

  const _BudgetCategoriesCard({
    required this.items,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Presupuesto por categoría',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < items.length; i++) ...[
              _BudgetCategoryRow(item: items[i], currency: currency),
              if (i < items.length - 1) const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Signed sum of uncontrolled adjustments for the month (negative is an
/// expense). Only shown when non-zero.
class _UncontrolledCard extends StatelessWidget {
  final double total;
  final String currency;

  const _UncontrolledCard({
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = total < 0;
    final tone = isExpense ? AppColors.authExpense : AppColors.authIncome;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: tone.withValues(alpha: 0.18),
              child: Icon(
                Icons.priority_high_rounded,
                size: 18,
                color: tone,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sin declarar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isExpense
                        ? 'Gasto no controlado este mes'
                        : 'Ingreso no controlado este mes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.authTextFooter,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(total.abs(), currency),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCategoryRow extends StatelessWidget {
  final _BudgetProgress item;
  final String currency;

  const _BudgetCategoryRow({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final categoryColor =
        colorFromHex(category.color, fallback: AppColors.authAccent);
    final barColor = item.isOverBudget ? AppColors.authExpense : categoryColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatCurrency(item.budgeted, currency)} / mes',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.authTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.authCardBorder,
                  color: barColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(item.spent, currency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryDonutChart extends StatelessWidget {
  final List<CategoryTotal> breakdown;
  final double total;
  final String currency;

  final String label;

  const _CategoryDonutChart({
    required this.breakdown,
    required this.total,
    required this.currency,
    this.label = 'Total gastos',
  });

  @override
  Widget build(BuildContext context) {
    const size = 128.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _DonutChartPainter(breakdown: breakdown),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(total, currency),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the donut segments from [CategoryTotal.percent] without a charting
/// library.
class _DonutChartPainter extends CustomPainter {
  final List<CategoryTotal> breakdown;
  final double strokeWidth;

  _DonutChartPainter({required this.breakdown}) : strokeWidth = 15;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track behind the segments in case rounding leaves a gap.
    final backgroundPaint = Paint()
      ..color = AppColors.authBackgroundTop
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * pi, false, backgroundPaint);

    double startAngle = -pi / 2;
    for (final item in breakdown) {
      if (item.percent <= 0) continue;

      final sweepAngle = (item.percent / 100) * 2 * pi;
      final paint = Paint()
        // Uncategorized has no color in the DB, so its segment is transparent.
        ..color = colorFromHex(
          item.category.color,
          fallback: Colors.transparent,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.breakdown != breakdown;
  }
}

class _CategoryLegendRow extends StatelessWidget {
  final CategoryTotal category;
  final String currency;

  const _CategoryLegendRow({required this.category, required this.currency});

  @override
  Widget build(BuildContext context) {
    // Uncategorized has no color: keep the dot transparent.
    final color =
        colorFromHex(category.category.color, fallback: Colors.transparent);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatCurrency(category.amount, currency),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: Text(
              '${category.percent.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
