import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../utils/currency_format.dart';

const double _barAreaHeight = 110;
const double _amountLabelHeight = 20;

class MonthlyBar {
  /// First day of the month.
  final DateTime month;

  /// Null when the month has no data; the chart shows its `missingLabel`.
  final double? value;

  const MonthlyBar({required this.month, required this.value});
}

/// One bar per month, oldest first; the last one is marked as in progress.
/// An optional dashed reference line (e.g. a budget) turns the bars that
/// exceed it red.
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

    var maxValue = 0.0;
    for (final bar in bars) {
      final value = bar.value;
      if (value != null && value > maxValue) maxValue = value;
    }
    if (reference != null && reference > maxValue) maxValue = reference;
    if (maxValue <= 0) maxValue = 1;

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
                    for (final bar in bars)
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _Bar(
                            label: bar.value == null
                                ? missingLabel
                                : formatCurrency(bar.value!, currency),
                            isMissing: bar.value == null,
                            height: _barHeight(bar.value, maxValue),
                            color: reference != null &&
                                    bar.value != null &&
                                    bar.value! > reference
                                ? AppColors.authExpense
                                : color,
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
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final bar in bars)
              Expanded(
                child: Text(
                  bar == bars.last
                      ? '${monthFormat.format(bar.month)} · en curso'
                      : monthFormat.format(bar.month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ),
          ],
        ),
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

  double _barHeight(double? value, double maxValue) {
    if (value == null || value <= 0) return 2;
    final height = value / maxValue * _barAreaHeight;
    return height < 2 ? 2 : height;
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
          child: FittedBox(
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
          ),
        ),
        Container(
          width: 36,
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
