import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/monthly_bar_chart.dart';
import '../../../../core/widgets/trend_card.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/category.dart';
import '../../domain/category_trend.dart';

/// Last-3-months spending (or income) of a category, with the monthly
/// budget as a dashed line when the category has one.
class CategoryTrendSection extends StatefulWidget {
  final Category category;
  final String currency;
  final TransactionViewModel transactionViewModel;

  const CategoryTrendSection({
    super.key,
    required this.category,
    required this.currency,
    required this.transactionViewModel,
  });

  @override
  State<CategoryTrendSection> createState() => _CategoryTrendSectionState();
}

class _CategoryTrendSectionState extends State<CategoryTrendSection> {
  late Future<CategoryTrend> _trend;

  @override
  void initState() {
    super.initState();
    _trend = _load();
  }

  Future<CategoryTrend> _load() async {
    final today = nowLocal();
    final entries = await widget.transactionViewModel.fetchCategoryEntries(
      categoryId: widget.category.id,
      since: categoryTrendStart(today),
    );
    return buildCategoryTrend(entries: entries, today: today);
  }

  void _retry() => setState(() => _trend = _load());

  @override
  Widget build(BuildContext context) {
    return TrendCard(
      title: 'Últimos 3 meses',
      child: FutureBuilder<CategoryTrend>(
        future: _trend,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.authAccent),
              ),
            );
          }
          if (snapshot.hasError) {
            return Row(
              children: [
                const Expanded(
                  child: Text(
                    'No se pudo cargar el gráfico.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _retry,
                  child: const Text('Reintentar'),
                ),
              ],
            );
          }
          return _TrendContent(
            trend: snapshot.requireData,
            category: widget.category,
            currency: widget.currency,
          );
        },
      ),
    );
  }
}

class _TrendContent extends StatelessWidget {
  final CategoryTrend trend;
  final Category category;
  final String currency;

  const _TrendContent({
    required this.trend,
    required this.category,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const Text(
        'Sin movimientos en los últimos 3 meses.',
        style: TextStyle(fontSize: 14, color: AppColors.authTextSecondary),
      );
    }

    final isExpense = category.type == 'expense';
    final budget =
        isExpense && category.hasBudget ? category.budgetAmount : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonthlyBarChart(
          bars: [
            for (final month in trend.months)
              MonthlyBar(month: month.month, value: month.total),
          ],
          currency: currency,
          color: colorFromHex(category.color, fallback: AppColors.authAccent),
          referenceValue: budget,
          referenceLabel: 'Presupuesto mensual',
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.authCardBorder),
        TrendSummaryRow(
          label: 'Promedio de los 2 meses anteriores',
          value: Text(
            formatCurrency(trend.previousMonthsAverage, currency),
            style: trendValueStyle,
          ),
        ),
        const Divider(height: 1, color: AppColors.authCardBorder),
        TrendSummaryRow(
          label: 'Vs. mismo período del mes anterior',
          value: TrendChangeValue(
            percent: trend.changePercent,
            // A rise is bad for spending and good for income.
            risingIsGood: !isExpense,
          ),
        ),
      ],
    );
  }
}
