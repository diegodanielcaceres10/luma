import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../utils/currency_format.dart';

const double _barAreaHeight = 110;
const double _amountLabelHeight = 20;
const double _barWidth = 36;
const double _minBarHeight = 2;

class MonthlyBar {
  /// First day of the month.
  final DateTime month;

  /// Null when the month has no data; the chart shows its `missingLabel`.
  final double? value;

  /// Overrides the bar color chosen by the chart.
  final Color? color;

  /// Optional second line under the month name.
  final String? caption;

  const MonthlyBar({
    required this.month,
    required this.value,
    this.color,
    this.caption,
  });
}

/// One bar per month, oldest first; the last one is marked as in progress.
/// An optional dashed reference line (e.g. a budget) turns the bars that
/// exceed it red.
///
/// When any value is negative the chart switches to a diverging layout:
/// a zero line in the middle, positive bars growing up and negative ones
/// down, both on the same scale. Without negatives the layout is the plain
/// one, bars growing from the bottom.
class MonthlyBarChart extends StatelessWidget {
  final List<MonthlyBar> bars;
  final String currency;
  final Color color;
  final double? referenceValue;
  final String referenceLabel;
  final String missingLabel;

  const MonthlyBarChart({
    super.key,
    required this.bars,
    required this.currency,
    required this.color,
    this.referenceValue,
    this.referenceLabel = '',
    this.missingLabel = 'Sin datos',
  });

  @override
  Widget build(BuildContext context) {
    final rawReference = referenceValue;
    final reference =
        rawReference != null && rawReference > 0 ? rawReference : null;
    final hasNegative = bars.any((bar) => (bar.value ?? 0) < 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hasNegative ? _diverging(reference) : _plain(reference),
        const SizedBox(height: 6),
        _MonthLabels(bars: bars),
        if (reference != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 18, child: _DashedLine()),
              const SizedBox(width: 8),
              Text(
                '$referenceLabel: ${formatCurrency(reference, currency)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.authTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _plain(double? reference) {
    var maxValue = 0.0;
    for (final bar in bars) {
      final value = bar.value;
      if (value != null && value > maxValue) maxValue = value;
    }
    if (reference != null && reference > maxValue) maxValue = reference;
    if (maxValue <= 0) maxValue = 1;

    return SizedBox(
      height: _barAreaHeight + _amountLabelHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                for (final bar in bars)
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _Bar(
                        label: bar.value == null
                            ? missingLabel
                            : formatCurrency(bar.value!, currency),
                        isMissing: bar.value == null,
                        height: _plainBarHeight(bar.value, maxValue),
                        color: bar.color ??
                            (reference != null &&
                                    bar.value != null &&
                                    bar.value! > reference
                                ? AppColors.authExpense
                                : color),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (reference != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: reference / maxValue * _barAreaHeight,
              child: const _DashedLine(),
            ),
        ],
      ),
    );
  }

  double _plainBarHeight(double? value, double maxValue) {
    if (value == null || value <= 0) return _minBarHeight;
    final height = value / maxValue * _barAreaHeight;
    return height < _minBarHeight ? _minBarHeight : height;
  }

  Widget _diverging(double? reference) {
    var maxPositive = 0.0;
    var maxNegative = 0.0;
    for (final bar in bars) {
      final value = bar.value;
      if (value == null) continue;
      if (value > maxPositive) maxPositive = value;
      if (-value > maxNegative) maxNegative = -value;
    }
    if (reference != null && reference > maxPositive) maxPositive = reference;

    // hasNegative guarantees maxNegative > 0, so the range is never zero.
    final scale = _barAreaHeight / (maxPositive + maxNegative);
    const totalHeight = _barAreaHeight + 2 * _amountLabelHeight;
    // Distance from the bottom of the chart to the zero line.
    final zeroFromBottom = _amountLabelHeight + maxNegative * scale;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: zeroFromBottom,
            height: 1,
            child: const ColoredBox(color: AppColors.authCardBorder),
          ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final bar in bars)
                  Expanded(
                    child: _DivergingColumn(
                      bar: bar,
                      scale: scale,
                      zeroFromBottom: zeroFromBottom,
                      totalHeight: totalHeight,
                      label: bar.value == null
                          ? missingLabel
                          : formatCurrency(bar.value!, currency),
                      color: bar.color ??
                          ((bar.value ?? 0) < 0
                              ? AppColors.authExpense
                              : color),
                    ),
                  ),
              ],
            ),
          ),
          if (reference != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: zeroFromBottom + reference * scale,
              child: const _DashedLine(),
            ),
        ],
      ),
    );
  }
}

class _MonthLabels extends StatelessWidget {
  final List<MonthlyBar> bars;

  const _MonthLabels({required this.bars});

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MMM', 'es');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final bar in bars)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bar == bars.last
                      ? '${monthFormat.format(bar.month)} · en curso'
                      : monthFormat.format(bar.month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.authTextSecondary,
                  ),
                ),
                if (bar.caption != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        bar.caption!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final bool isMissing;
  final double height;
  final Color color;

  const _Bar({
    required this.label,
    required this.isMissing,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _amountLabelHeight,
          child: _AmountLabel(label: label, isMissing: isMissing),
        ),
        Container(
          width: _barWidth,
          height: height,
          decoration: BoxDecoration(
            color: isMissing ? AppColors.authCardBorder : color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
      ],
    );
  }
}

/// One month of the diverging layout. Positive (and zero or missing) bars
/// grow up from the zero line with their label above; negative bars grow
/// down with their label below.
class _DivergingColumn extends StatelessWidget {
  final MonthlyBar bar;
  final double scale;
  final double zeroFromBottom;
  final double totalHeight;
  final String label;
  final Color color;

  const _DivergingColumn({
    required this.bar,
    required this.scale,
    required this.zeroFromBottom,
    required this.totalHeight,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final value = bar.value;
    final isMissing = value == null;
    final isNegative = value != null && value < 0;

    var height = value == null ? _minBarHeight : value.abs() * scale;
    if (height < _minBarHeight) height = _minBarHeight;

    final fill = isMissing ? AppColors.authCardBorder : color;
    final barBox = Center(
      child: SizedBox(
        width: _barWidth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: isNegative
                ? const BorderRadius.vertical(bottom: Radius.circular(6))
                : const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
      ),
    );
    final labelBox = Center(
      child: _AmountLabel(label: label, isMissing: isMissing),
    );

    // Distance from the top of the chart to the zero line.
    final zeroFromTop = totalHeight - zeroFromBottom;

    return Stack(
      children: [
        if (isNegative) ...[
          Positioned(
            left: 0,
            right: 0,
            top: zeroFromTop,
            height: height,
            child: barBox,
          ),
          Positioned(
            left: 0,
            right: 0,
            top: zeroFromTop + height,
            height: _amountLabelHeight,
            child: labelBox,
          ),
        ] else ...[
          Positioned(
            left: 0,
            right: 0,
            bottom: zeroFromBottom,
            height: height,
            child: barBox,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: zeroFromBottom + height,
            height: _amountLabelHeight,
            child: labelBox,
          ),
        ],
      ],
    );
  }
}

class _AmountLabel extends StatelessWidget {
  final String label;
  final bool isMissing;

  const _AmountLabel({required this.label, required this.isMissing});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isMissing ? FontWeight.w400 : FontWeight.w600,
          color: isMissing
              ? AppColors.authTextSecondary
              : AppColors.authTextPrimary,
        ),
      ),
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
