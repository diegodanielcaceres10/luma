import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/month_filter_button.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../accounts/presentation/view_models/closed_month_justification.dart';
import '../../../accounts/presentation/view_models/monthly_balance_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../export/transactions_statistics_screen_pdf_builder.dart';
import '../view_models/transaction_view_model.dart';
import '../view_models/transactions_statistics_report.dart';
import '../widgets/statistics/budget_categories_card.dart';
import '../widgets/statistics/donut_with_legend.dart';
import '../widgets/statistics/justify_month_card.dart';
import '../widgets/statistics/statistics_header.dart';
import '../widgets/statistics/summary_cards.dart';
import '../widgets/statistics/uncontrolled_card.dart';

class TransactionsStatisticsScreen extends StatefulWidget {
  final TransactionViewModel transactionViewModel;

  final CategoryViewModel categoryViewModel;
  final AccountViewModel accountViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final String currency;

  /// Opens the flow that justifies [month] for the accounts left without
  /// loading in it.
  final ValueChanged<DateTime> onJustifyMonth;

  /// Opens the comparison of [month] against the month before it.
  final ValueChanged<DateTime> onCompareMonths;

  const TransactionsStatisticsScreen({
    super.key,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.accountViewModel,
    required this.monthlyBalanceViewModel,
    required this.currency,
    required this.onJustifyMonth,
    required this.onCompareMonths,
  });

  @override
  State<TransactionsStatisticsScreen> createState() =>
      _TransactionsStatisticsScreenState();
}

class _TransactionsStatisticsScreenState
    extends State<TransactionsStatisticsScreen> {
  bool _isExportingPdf = false;
  bool _isExportingFullPdf = false;

  @override
  void initState() {
    super.initState();
    // Always reloaded: it tells which accounts were left without loading.
    widget.monthlyBalanceViewModel.loadOpeningMonths();
  }

  void _showFloatingSnackBar(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E2922),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: AppColors.authCardBorder,
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? AppColors.error : AppColors.authAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.authTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Offers to justify a past month for the accounts that have neither an
  /// opening balance nor movements in it. Null while that isn't known yet or
  /// when there is nothing to offer.
  Widget? _justifyMonthCard({
    required DateTime month,
    required bool isCurrentMonth,
    required String monthInSentence,
  }) {
    final vm = widget.transactionViewModel;
    final balances = widget.monthlyBalanceViewModel;
    if (isCurrentMonth ||
        vm.isStatisticsLoading ||
        vm.statisticsErrorMessage != null ||
        !balances.openingMonthsLoaded) {
      return null;
    }

    final accounts = ClosedMonthJustification.eligibleAccounts(
      month: month,
      activeAccounts: widget.accountViewModel.activeAccounts,
      openingMonthsByAccount: balances.openingMonthsByAccount,
      monthEntries: vm.statisticsEntries,
    );
    if (accounts.isEmpty) return null;

    return StatisticsJustifyMonthCard(
      monthLabel: monthInSentence,
      accountNames: [for (final account in accounts) account.name],
      onPressed: () => widget.onJustifyMonth(month),
    );
  }

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
        _showFloatingSnackBar(
          'No se pudo generar el PDF.',
          isError: true,
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
      listenable: Listenable.merge([
        widget.transactionViewModel,
        widget.categoryViewModel,
        widget.accountViewModel,
        widget.monthlyBalanceViewModel,
      ]),
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
          onCompareMonths: () => widget.onCompareMonths(month),
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

        final justifyCard = _justifyMonthCard(
          month: month,
          isCurrentMonth: isCurrentMonth,
          monthInSentence: monthInSentence,
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
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.authAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.authCardFill,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.authCardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.authExpense
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.authExpense
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.authExpense,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.authTextSecondary,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.authAccent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () => vm.loadStatisticsMonth(month),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text(
                                  'Reintentar',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        if (breakdown.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      if (justifyCard != null) ...[
                        const SizedBox(height: 16),
                        justifyCard,
                      ],
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
                        padding: const EdgeInsets.only(top: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.authCardFill,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.authCardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.authAccent
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.authAccent
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.pie_chart_outline_rounded,
                                  color: AppColors.authAccent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isCurrentMonth
                                    ? 'Todavía no hay gastos este mes.'
                                    : 'No hay gastos registrados en $monthInSentence.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.authTextPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Los gastos que registres se desglosarán automáticamente aquí.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.authTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    if (justifyCard != null) ...[
                      const SizedBox(height: 16),
                      justifyCard,
                    ],
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
                    const SizedBox(height: 28),
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
                          letterSpacing: -0.5,
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
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.authCardFill,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.authCardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: StatisticsDonutWithLegend(
                            breakdown: expenseTypeBreakdown,
                            total: expenseTypeTotal,
                            currency: widget.currency,
                            label: 'Gasto real',
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
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
                          letterSpacing: -0.5,
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
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.authCardFill,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.authCardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: StatisticsDonutWithLegend(
                            breakdown: categorizedBreakdown,
                            total: categorizedTotal,
                            currency: widget.currency,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
