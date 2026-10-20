import 'package:flutter/material.dart';

import '../../view_models/transaction_view_model.dart';
import 'category_donut_chart.dart';
import 'category_legend_row.dart';

/// A category donut chart with its legend.
///
/// With room (see [twoColumnsMinWidth]) each takes half of the width, centered
/// in its half. Without it, the legend follows the chart closely so it keeps
/// as much width as possible.
class StatisticsDonutWithLegend extends StatelessWidget {
  /// Narrowest width that still gives the legend a usable half: names like
  /// "No categorizados" fit without being cut.
  static const double twoColumnsMinWidth = 440;

  static const double _compactGap = 18;

  /// In two columns the chart takes this share of its half, within
  /// [_maxChartSize], so a taller card follows a wider one.
  static const double _chartShareOfHalf = 0.7;
  static const double _maxChartSize = 240;

  final List<CategoryTotal> breakdown;
  final double total;
  final String currency;

  /// Text in the middle of the chart; the chart's own default when null.
  final String? label;

  const StatisticsDonutWithLegend({
    super.key,
    required this.breakdown,
    required this.total,
    required this.currency,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    Widget chartOfSize(double size) => label == null
        ? StatisticsCategoryDonutChart(
            breakdown: breakdown,
            total: total,
            currency: currency,
            size: size,
          )
        : StatisticsCategoryDonutChart(
            breakdown: breakdown,
            total: total,
            currency: currency,
            label: label!,
            size: size,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= twoColumnsMinWidth;

        if (twoColumns) {
          final size = (constraints.maxWidth / 2 * _chartShareOfHalf).clamp(
            StatisticsCategoryDonutChart.defaultSize,
            _maxChartSize,
          );
          return Row(
            children: [
              Expanded(child: Center(child: chartOfSize(size))),
              Expanded(
                child: StatisticsCategoryLegend(
                  breakdown: breakdown,
                  currency: currency,
                  alignment: Alignment.center,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            chartOfSize(StatisticsCategoryDonutChart.defaultSize),
            const SizedBox(width: _compactGap),
            Expanded(
              child: StatisticsCategoryLegend(
                breakdown: breakdown,
                currency: currency,
              ),
            ),
          ],
        );
      },
    );
  }
}
