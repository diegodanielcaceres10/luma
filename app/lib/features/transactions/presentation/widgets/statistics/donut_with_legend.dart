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
    final chart = label == null
        ? StatisticsCategoryDonutChart(
            breakdown: breakdown,
            total: total,
            currency: currency,
          )
        : StatisticsCategoryDonutChart(
            breakdown: breakdown,
            total: total,
            currency: currency,
            label: label!,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= twoColumnsMinWidth;

        if (twoColumns) {
          return Row(
            children: [
              Expanded(child: Center(child: chart)),
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
            chart,
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
