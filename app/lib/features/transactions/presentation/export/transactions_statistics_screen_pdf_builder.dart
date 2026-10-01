import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../view_models/transaction_view_model.dart' show CategoryTotal;
import '../view_models/transactions_statistics_report.dart';

const _lumaUrl = 'diegodanielcaceres10.github.io/luma';

/// Snapshot of the statistics for one month, taken at export time so the
/// PDF does not change if the user switches months meanwhile.
class TransactionsStatisticsScreenPdfData {
  final DateTime month;

  final String monthLabel;
  final String currency;
  final TransactionsStatisticsReport report;

  // The PDF is only generated for closed months, so the change vs. the
  // previous month is always comparable.
  final double? incomeChangePercent;
  final double? expenseChangePercent;
  final double? netChangePercent;

  const TransactionsStatisticsScreenPdfData({
    required this.month,
    required this.monthLabel,
    required this.currency,
    required this.report,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
    required this.netChangePercent,
  });

  String get fileName =>
      'luma-estadisticas-${month.year}-${month.month.toString().padLeft(2, '0')}.pdf';
}

/// Builds the PDF of the statistics screen for a closed month, with the same
/// sections and order as the screen. Uses the bundled Roboto fonts because
/// the default PDF fonts lack the € symbol and some accents.
class TransactionsStatisticsScreenPdfBuilder {
  TransactionsStatisticsScreenPdfBuilder._();

  // Print-friendly colors, not the dark theme ones.
  static const _textPrimary = PdfColor.fromInt(0xFF111827);
  static const _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _cardFill = PdfColor.fromInt(0xFFF9FAFB);

  static const _donutSize = 100.0;
  static const _donutStroke = 13.0;

  // A row cannot break across pages, so a long legend is laid out below the
  // donut (one widget per row) instead of beside it.
  static const _maxSideBySideLegendItems = 12;

  static PdfColor _pdfColor(Color color) => PdfColor.fromInt(color.toARGB32());

  static const _copyright = '© 2026 Diego Daniel Caceres';
  static const _portfolioLabel = 'diegodanielcaceres10.github.io/nura';

  static Future<Uint8List> build(
    TransactionsStatisticsScreenPdfData data,
  ) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
    );

    final generatedOn =
        DateFormat('dd-MM-yyyy HH:mm', 'es').format(DateTime.now());

    final doc = pw.Document(
      title: 'Estadísticas ${data.monthLabel}',
      author: 'Luma',
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generado con Luma · $generatedOn hs',
                    style:
                        const pw.TextStyle(fontSize: 9, color: _textSecondary),
                  ),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style:
                        const pw.TextStyle(fontSize: 9, color: _textSecondary),
                  ),
                ],
              ),
              if (context.pageNumber == context.pagesCount) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  '$_copyright · $_portfolioLabel · $_lumaUrl',
                  style:
                      const pw.TextStyle(fontSize: 7.5, color: _textSecondary),
                ),
              ],
            ],
          ),
        ),
        // Same order as the statistics screen. The budget card is left out:
        // the screen only shows it for the month in progress.
        build: (context) {
          final report = data.report;

          return [
            _header(data, logo),
            pw.SizedBox(height: 22),
            _summaryRow(data),
            if (report.hasUncontrolledTotal) ...[
              pw.SizedBox(height: 10),
              _uncontrolledCard(report, data.currency),
            ],
            if (report.breakdown.isEmpty) ...[
              pw.SizedBox(height: 26),
              pw.Text(
                'No hay gastos registrados en ${data.monthLabel.toLowerCase()}.',
                style: const pw.TextStyle(fontSize: 11, color: _textSecondary),
              ),
            ] else ...[
              if (report.expenseTypeBreakdown.isNotEmpty) ...[
                pw.SizedBox(height: 26),
                ..._breakdownSection(
                  title: 'Categorizado, sin categoría y no declarado',
                  total: report.expenseTypeTotal,
                  breakdown: report.expenseTypeBreakdown,
                  data: data,
                  donutLabel: 'Gasto real',
                ),
              ],
              if (report.categorizedBreakdown.isNotEmpty) ...[
                pw.SizedBox(height: 26),
                ..._breakdownSection(
                  title: 'Gastos por categoría',
                  total: report.categorizedTotal,
                  breakdown: report.categorizedBreakdown,
                  data: data,
                  donutLabel: 'Total gastos',
                ),
              ],
            ],
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(
    TransactionsStatisticsScreenPdfData data,
    pw.MemoryImage logo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Image(logo, width: 18, height: 18),
            pw.SizedBox(width: 6),
            pw.Text(
              'Luma',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _pdfColor(AppColors.authAccentDark),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Estadísticas',
          style: const pw.TextStyle(
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          data.monthLabel,
          style: const pw.TextStyle(fontSize: 14, color: _textSecondary),
        ),
        pw.SizedBox(height: 14),
        pw.Container(height: 1, color: _border),
      ],
    );
  }

  static pw.Widget _summaryRow(TransactionsStatisticsScreenPdfData data) {
    final report = data.report;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _summaryCard(
            label: 'Ingresos',
            amount: report.income,
            currency: data.currency,
            changePercent: data.incomeChangePercent,
            isFavorable: (p) => p >= 0,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _summaryCard(
            label: 'Gastos',
            amount: report.expenses,
            currency: data.currency,
            changePercent: data.expenseChangePercent,
            // For expenses, spending less than last month is the improvement.
            isFavorable: (p) => p <= 0,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _summaryCard(
            label: 'Balance del mes',
            amount: report.netResult,
            currency: data.currency,
            changePercent: data.netChangePercent,
            isFavorable: (p) => p >= 0,
          ),
        ),
      ],
    );
  }

  static pw.Widget _summaryCard({
    required String label,
    required double amount,
    required String currency,
    required double? changePercent,
    required bool Function(double percent) isFavorable,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _cardFill,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: _textSecondary),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            formatCurrency(amount, currency),
            style: const pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          if (changePercent != null) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              '${changePercent > 0 ? '+' : ''}'
              '${changePercent.toStringAsFixed(0)}% vs. mes anterior',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: _pdfColor(
                  isFavorable(changePercent)
                      ? AppColors.authAccentDark
                      : AppColors.authExpense,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _uncontrolledCard(
    TransactionsStatisticsReport report,
    String currency,
  ) {
    final tone = _pdfColor(
      report.isUncontrolledExpense
          ? AppColors.authExpense
          : AppColors.authIncome,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _cardFill,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border, width: 0.8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Sin declarar',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  report.isUncontrolledExpense
                      ? 'Gasto no controlado este mes'
                      : 'Ingreso no controlado este mes',
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            formatCurrency(report.uncontrolledTotal.abs(), currency),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }

  /// Title, total spent and a donut with its legend, like the screen sections.
  static List<pw.Widget> _breakdownSection({
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
          color: _textSecondary,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        formatCurrency(total, data.currency),
        style: const pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: _textPrimary,
        ),
      ),
      pw.Text(
        'gastados en ${data.monthLabel.toLowerCase()}',
        style: const pw.TextStyle(fontSize: 10, color: _textSecondary),
      ),
      pw.SizedBox(height: 14),
      if (isLongLegend) ...[
        donut,
        pw.SizedBox(height: 10),
        ...legendRows,
      ] else
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: _cardFill,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _border, width: 0.8),
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

  static PdfColor _categoryColor(CategoryTotal item) => _pdfColor(
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
                    style:
                        const pw.TextStyle(fontSize: 8, color: _textSecondary),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    formatCurrency(total, currency),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _textPrimary,
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
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
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
                color: _textPrimary,
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            formatCurrency(item.amount, currency),
            style: const pw.TextStyle(fontSize: 10.5, color: _textPrimary),
          ),
          pw.SizedBox(width: 6),
          pw.SizedBox(
            width: 30,
            child: pw.Text(
              '${item.percent.toStringAsFixed(0)}%',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 10, color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
