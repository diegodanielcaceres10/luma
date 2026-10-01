import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/category.dart';
import '../../domain/category_trend.dart';

const double _barAreaHeight = 110;
const double _amountLabelHeight = 20;

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
    final today = DateTime.now();
    final entries = await widget.transactionViewModel.fetchCategoryEntries(
      categoryId: widget.category.id,
      since: categoryTrendStart(today),
    );
    return buildCategoryTrend(entries: entries, today: today);
  }

  void _retry() => setState(() => _trend = _load());

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimos 3 meses',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<CategoryTrend>(
            future: _trend,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.authAccent,
                    ),
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
        ],
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
    final maxValue = [
      ...trend.months.map((m) => m.total),
      if (budget != null) budget,
    ].reduce((a, b) => a > b ? a : b);
    final baseColor =
        colorFromHex(category.color, fallback: AppColors.authAccent);
    final monthFormat = DateFormat('MMM', 'es');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _barAreaHeight + _amountLabelHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    for (final month in trend.months)
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _Bar(
                            label: formatCurrency(month.total, currency),
                            height: _barHeight(month.total, maxValue),
                            color: budget != null && month.total > budget
                                ? AppColors.authExpense
                                : baseColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (budget != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: budget / maxValue * _barAreaHeight,
                  child: const _DashedLine(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final month in trend.months)
              Expanded(
                child: Text(
                  month == trend.months.last
                      ? '${monthFormat.format(month.month)} · en curso'
                      : monthFormat.format(month.month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ),
          ],
        ),
        if (budget != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 18, child: _DashedLine()),
              const SizedBox(width: 8),
              Text(
                'Presupuesto mensual: ${formatCurrency(budget, currency)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.authTextSecondary,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.authCardBorder),
        _SummaryRow(
          label: 'Promedio de los 2 meses anteriores',
          value: Text(
            formatCurrency(trend.previousMonthsAverage, currency),
            style: _valueStyle,
          ),
        ),
        const Divider(height: 1, color: AppColors.authCardBorder),
        _SummaryRow(
          label: 'Vs. mismo período del mes anterior',
          value: _ChangeValue(
            percent: trend.changePercent,
            // A rise is bad for spending and good for income.
            risingIsGood: !isExpense,
          ),
        ),
      ],
    );
  }

  double _barHeight(double total, double maxValue) {
    if (total <= 0) return 2;
    final height = total / maxValue * _barAreaHeight;
    return height < 2 ? 2 : height;
  }
}

const _valueStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: AppColors.authTextPrimary,
);

class _Bar extends StatelessWidget {
  final String label;
  final double height;
  final Color color;

  const _Bar({required this.label, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _amountLabelHeight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
        ),
        Container(
          width: 36,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final Widget value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          value,
        ],
      ),
    );
  }
}

class _ChangeValue extends StatelessWidget {
  final double? percent;
  final bool risingIsGood;

  const _ChangeValue({required this.percent, required this.risingIsGood});

  @override
  Widget build(BuildContext context) {
    final value = percent;
    if (value == null) return const Text('—', style: _valueStyle);

    final rounded = value.round();
    if (rounded == 0) return const Text('0%', style: _valueStyle);

    final rising = rounded > 0;
    final good = rising == risingIsGood;
    final color = good ? AppColors.authIncome : AppColors.authExpense;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          rising ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${rounded.abs()}%',
          style: _valueStyle.copyWith(color: color),
        ),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.authTextSecondary
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      final end = x + dash > size.width ? size.width : x + dash;
      canvas.drawLine(Offset(x, 0), Offset(end, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}
