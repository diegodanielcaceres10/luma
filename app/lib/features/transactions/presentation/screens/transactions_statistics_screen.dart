import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/month_filter_button.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../export/transactions_statistics_screen_pdf_builder.dart';
import '../view_models/transaction_view_model.dart';
import '../view_models/transactions_statistics_report.dart';
import '../widgets/statistics/budget_categories_card.dart';
import '../widgets/statistics/category_donut_chart.dart';
import '../widgets/statistics/category_legend_row.dart';
import '../widgets/statistics/statistics_header.dart';
import '../widgets/statistics/summary_cards.dart';
import '../widgets/statistics/uncontrolled_card.dart';

class TransactionsStatisticsScreen extends StatefulWidget {
  final TransactionViewModel transactionViewModel;

  final CategoryViewModel categoryViewModel;
  final String currency;

  const TransactionsStatisticsScreen({
    super.key,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.currency,
  });

  @override
  State<TransactionsStatisticsScreen> createState() =>
      _TransactionsStatisticsScreenState();
}

class _TransactionsStatisticsScreenState
    extends State<TransactionsStatisticsScreen> {
  bool _isExportingPdf = false;
  bool _isExportingFullPdf = false;

  /// Generates the month's PDF and downloads it (web) or opens the share
  /// sheet (mobile). Only offered for closed months. With
  /// [includeMovements] the PDF also lists the month's movements.
  Future<void> _exportPdf({bool includeMovements = false}) async {
    if (_isExportingPdf || _isExportingFullPdf) return;

    // Snapshot before the first await so the PDF matches the month where the
    // user tapped, even if they switch months while it generates.
    final vm = widget.transactionViewModel;
    final data = TransactionsStatisticsScreenPdfData(
      month: vm.statisticsMonth,
      monthLabel: formatMonthLabel(vm.statisticsMonth),
      currency: widget.currency,
      report: TransactionsStatisticsReport.fromTotals(
        income: vm.statisticsIncome,
        expenses: vm.statisticsExpenses,
        netResult: vm.statisticsNetResult,
        uncontrolledTotal: vm.statisticsUncontrolledTotal,
        breakdown: List.of(vm.statisticsCategoryBreakdown),
      ),
      incomeChangePercent: vm.statisticsIncomeChangePercent,
      expenseChangePercent: vm.statisticsExpenseChangePercent,
      netChangePercent: vm.statisticsNetResultChangePercent,
      movements: includeMovements ? vm.statisticsEntries : null,
    );

    setState(() {
      _isExportingPdf = !includeMovements;
      _isExportingFullPdf = includeMovements;
    });
    try {
      final bytes = await TransactionsStatisticsScreenPdfBuilder.build(data);
      await Printing.sharePdf(bytes: bytes, filename: data.fileName);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el PDF.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
          _isExportingFullPdf = false;
        });
      }
    }
  }

  List<StatisticsBudgetProgress> get _budgetProgress {
    final spentByCategoryId = <String, double>{
      for (final total
          in widget.transactionViewModel.statisticsCategoryBreakdown)
        if (total.category.id != null) total.category.id!: total.amount,
    };

    return widget.categoryViewModel.budgetedCategories
        .map((category) => StatisticsBudgetProgress(
              category: category,
              budgeted: category.budgetAmount ?? 0,
              spent: spentByCategoryId[category.id] ?? 0,
            ))
        .toList();
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

        final header = StatisticsHeader(
          selectedMonth: month,
          onMonthChanged: vm.loadStatisticsMonth,
          onExportPdf: canExportPdf ? () => _exportPdf() : null,
          onExportFullPdf: canExportPdf
              ? () => _exportPdf(includeMovements: true)
              : null,
          isExportingPdf: _isExportingPdf,
          isExportingFullPdf: _isExportingFullPdf,
        );

        // Budgets track the current month only.
        final budgetProgress = isCurrentMonth
            ? _budgetProgress
            : const <StatisticsBudgetProgress>[];
        final budgetCard = budgetProgress.isEmpty
            ? null
            : StatisticsBudgetCategoriesCard(
                items: budgetProgress,
                currency: widget.currency,
              );

        final uncontrolledCard = !vm.statisticsHasUncontrolledTotal
            ? null
            : StatisticsUncontrolledCard(
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

        final report = TransactionsStatisticsReport.fromTotals(
          income: vm.statisticsIncome,
          expenses: vm.statisticsExpenses,
          netResult: vm.statisticsNetResult,
          uncontrolledTotal: vm.statisticsUncontrolledTotal,
          breakdown: vm.statisticsCategoryBreakdown,
        );
        final breakdown = report.breakdown;
        // Uncategorized entries appear in the breakdown below, not in the
        // categories chart.
        final categorizedBreakdown = report.categorizedBreakdown;
        final categorizedTotal = report.categorizedTotal;
        final expenseTypeBreakdown = report.expenseTypeBreakdown;
        final expenseTypeTotal = report.expenseTypeTotal;

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
              StatisticsSummaryCardsRow(
                income: report.income,
                expenses: report.expenses,
                netResult: report.netResult,
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
            StatisticsSummaryCardsRow(
              income: report.income,
              expenses: report.expenses,
              netResult: report.netResult,
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
                      StatisticsCategoryDonutChart(
                        breakdown: expenseTypeBreakdown,
                        total: expenseTypeTotal,
                        currency: widget.currency,
                        label: 'Gasto real',
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: expenseTypeBreakdown
                              .map((c) => StatisticsCategoryLegendRow(
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
                      StatisticsCategoryDonutChart(
                        breakdown: categorizedBreakdown,
                        total: categorizedTotal,
                        currency: widget.currency,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: categorizedBreakdown
                              .map((c) => StatisticsCategoryLegendRow(
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
