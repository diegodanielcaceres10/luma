import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/category_visuals.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../view_models/transaction_view_model.dart';

class StatisticsCategoryDonutChart extends StatelessWidget {
  /// Diameter the proportions below were designed for.
  static const double defaultSize = 128;

  final List<CategoryTotal> breakdown;
  final double total;
  final String currency;

  final String label;

  /// Diameter in logical pixels. Ring, padding and text scale with it.
  final double size;

  const StatisticsCategoryDonutChart({
    super.key,
    required this.breakdown,
    required this.total,
    required this.currency,
    this.label = 'Total gastos',
    this.size = defaultSize,
  });

  @override
  Widget build(BuildContext context) {
    final scale = size / defaultSize;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              breakdown: breakdown,
              strokeWidth: 15 * scale,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(28 * scale),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11 * scale,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    formatCurrency(total, currency),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14 * scale,
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

  _DonutChartPainter({required this.breakdown, required this.strokeWidth});

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
    return oldDelegate.breakdown != breakdown ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
