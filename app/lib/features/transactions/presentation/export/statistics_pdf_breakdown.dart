import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../view_models/transaction_view_model.dart' show CategoryTotal;
import 'statistics_pdf_style.dart';
import 'transactions_statistics_pdf_data.dart';

/// Spending breakdown (donut and legend) of the statistics PDF.
class StatisticsPdfBreakdown {
  StatisticsPdfBreakdown._();

  static const _donutSize = 100.0;

  static const _donutStroke = 13.0;

  // A row cannot break across pages, so a long legend is laid out below the
  // donut (one widget per row) instead of beside it.
  static const _maxSideBySideLegendItems = 12;

  /// Title, total spent and a donut with its legend, like the screen sections.
  static List<pw.Widget> section({
    required String title,
    required double total,
    required List<CategoryTotal> breakdown,
    required TransactionsStatisticsScreenPdfData data,
    required String donutLabel,
  }) {
    final donut = _donutChart(
      breakdown: breakdown,
      total: total,
      currency: data.currency,
      label: donutLabel,
    );
    final legendRows = [
      for (final item in breakdown) _legendRow(item, data.currency),
    ];
    final isLongLegend = breakdown.length > _maxSideBySideLegendItems;

    return [
      pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: kPdfTextSecondary,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        formatCurrency(total, data.currency),
        style: const pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: kPdfTextPrimary,
        ),
      ),
      pw.Text(
        'gastados en ${data.monthLabel.toLowerCase()}',
        style: const pw.TextStyle(fontSize: 10, color: kPdfTextSecondary),
      ),
      pw.SizedBox(height: 10),
      if (isLongLegend) ...[
        donut,
        pw.SizedBox(height: 10),
        ...legendRows,
      ] else
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: kPdfCardFill,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: kPdfBorder, width: 0.8),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              donut,
              pw.SizedBox(width: 18),
              pw.Expanded(child: pw.Column(children: legendRows)),
            ],
          ),
        ),
    ];
  }

  static PdfColor _categoryColor(CategoryTotal item) => pdfColor(
        colorFromHex(item.category.color, fallback: AppColors.authAccent),
      );

  static pw.Widget _donutChart({
    required List<CategoryTotal> breakdown,
    required double total,
    required String currency,
    required String label,
  }) {
    final segments = [
      for (final item in breakdown)
        if (item.percent > 0)
          (percent: item.percent, color: _categoryColor(item)),
    ];

    return pw.SizedBox(
      width: _donutSize,
      height: _donutSize,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.CustomPaint(
            size: const PdfPoint(_donutSize, _donutSize),
            painter: (canvas, size) => _paintDonut(canvas, size, segments),
          ),
          pw.SizedBox(
            width: _donutSize - _donutStroke * 2 - 10,
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    label,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: kPdfTextSecondary,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    formatCurrency(total, currency),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: kPdfTextPrimary,
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

  /// Draws each segment as a stroked polyline so it only needs the basic path
  /// operations. Starts at 12 o'clock and goes clockwise, like the screen.
  static void _paintDonut(
    PdfGraphics canvas,
    PdfPoint size,
    List<({double percent, PdfColor color})> segments,
  ) {
    final center = PdfPoint(size.x / 2, size.y / 2);
    final radius = (math.min(size.x, size.y) - _donutStroke) / 2;
    const stepRadians = math.pi / 90; // 2 degrees per line segment

    canvas.setLineWidth(_donutStroke);

    var startAngle = 0.0;
    for (final segment in segments) {
      final sweep = (segment.percent / 100) * 2 * math.pi;
      final steps = math.max(1, (sweep / stepRadians).ceil());

      canvas.setStrokeColor(segment.color);
      for (var i = 0; i <= steps; i++) {
        final angle = startAngle + sweep * i / steps;
        final x = center.x + radius * math.sin(angle);
        final y = center.y + radius * math.cos(angle);
        if (i == 0) {
          canvas.moveTo(x, y);
        } else {
          canvas.lineTo(x, y);
        }
      }
      canvas.strokePath();

      startAngle += sweep;
    }
  }

  static pw.Widget _legendRow(CategoryTotal item, String currency) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              color: _categoryColor(item),
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              item.category.name,
              maxLines: 1,
              style: const pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: kPdfTextPrimary,
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            formatCurrency(item.amount, currency),
            style: const pw.TextStyle(fontSize: 10.5, color: kPdfTextPrimary),
          ),
          pw.SizedBox(width: 6),
          pw.SizedBox(
            width: 30,
            child: pw.Text(
              '${item.percent.toStringAsFixed(0)}%',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 10, color: kPdfTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
