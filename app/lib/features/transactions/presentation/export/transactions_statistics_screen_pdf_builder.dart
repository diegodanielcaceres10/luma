import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/date_format.dart';
import 'statistics_pdf_breakdown.dart';
import 'statistics_pdf_movements.dart';
import 'statistics_pdf_style.dart';
import 'statistics_pdf_summary.dart';
import 'transactions_statistics_pdf_data.dart';

export 'transactions_statistics_pdf_data.dart';

const _lumaUrl = 'diegodanielcaceres10.github.io/luma';

/// Everything the PDF layout needs, so it can run in a background isolate.
/// Assets are loaded beforehand because isolates cannot read the bundle.
class _PdfJob {
  final TransactionsStatisticsScreenPdfData data;
  final Uint8List regularFont;
  final Uint8List boldFont;
  final Uint8List logo;
  final String generatedOn;

  const _PdfJob({
    required this.data,
    required this.regularFont,
    required this.boldFont,
    required this.logo,
    required this.generatedOn,
  });
}

/// Builds the PDF of the statistics screen for a closed month, with the same
/// sections and order as the screen. When the data carries movements, they
/// follow on their own pages after the summary. Uses the bundled Roboto fonts
/// because the default PDF fonts lack the € symbol and some accents.
class TransactionsStatisticsScreenPdfBuilder {
  TransactionsStatisticsScreenPdfBuilder._();

  // Compact spacing so a typical month (a few categories) fits on one page.
  static const _sectionGap = 18.0;

  static const _copyright = '© 2026 Diego Daniel Caceres';

  static const _portfolioLabel = 'diegodanielcaceres10.github.io/nura';

  static Future<Uint8List> build(
    TransactionsStatisticsScreenPdfData data,
  ) async {
    final job = _PdfJob(
      data: data,
      regularFont: (await rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          .buffer
          .asUint8List(),
      boldFont: (await rootBundle.load('assets/fonts/Roboto-Bold.ttf'))
          .buffer
          .asUint8List(),
      logo: (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
      generatedOn: formatDateTime(nowLocal()),
    );

    // Let the loading indicator paint before the heavy work starts.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // The layout is CPU-heavy: run it off the UI thread so the indicator
    // keeps spinning. The web has no isolates, so it runs in place there.
    return kIsWeb ? _render(job) : compute(_render, job);
  }

  static Future<Uint8List> _render(_PdfJob job) async {
    final data = job.data;
    final generatedOn = job.generatedOn;
    final regular = pw.Font.ttf(ByteData.sublistView(job.regularFont));
    final bold = pw.Font.ttf(ByteData.sublistView(job.boldFont));
    final logo = pw.MemoryImage(job.logo);

    final doc = pw.Document(
      title: 'Estadísticas ${data.monthLabel}',
      author: 'Luma',
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
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
                        const pw.TextStyle(
                          fontSize: 9,
                          color: kPdfTextSecondary,
                        ),
                  ),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style:
                        const pw.TextStyle(
                          fontSize: 9,
                          color: kPdfTextSecondary,
                        ),
                  ),
                ],
              ),
              if (context.pageNumber == context.pagesCount) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  '$_copyright · $_portfolioLabel · $_lumaUrl',
                  style:
                      const pw.TextStyle(
                        fontSize: 7.5,
                        color: kPdfTextSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
        // Same order as the statistics screen. The budget card is left out:
        // the screen only shows it for the month in progress.
        build: (context) {
          final report = data.report;
          final movements = data.movements;

          return [
            StatisticsPdfSummary.header(data, logo),
            pw.SizedBox(height: 16),
            StatisticsPdfSummary.summaryRow(data),
            if (report.hasUncontrolledTotal) ...[
              pw.SizedBox(height: 10),
              StatisticsPdfSummary.uncontrolledCard(report, data.currency),
            ],
            if (report.breakdown.isEmpty) ...[
              pw.SizedBox(height: _sectionGap),
              pw.Text(
                'No hay gastos registrados en ${data.monthLabel.toLowerCase()}.',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: kPdfTextSecondary,
                ),
              ),
            ] else ...[
              if (report.expenseTypeBreakdown.isNotEmpty) ...[
                pw.SizedBox(height: _sectionGap),
                ...StatisticsPdfBreakdown.section(
                  title: 'Categorizado, sin categoría y no declarado',
                  total: report.expenseTypeTotal,
                  breakdown: report.expenseTypeBreakdown,
                  data: data,
                  donutLabel: 'Gasto real',
                ),
              ],
              if (report.categorizedBreakdown.isNotEmpty) ...[
                pw.SizedBox(height: _sectionGap),
                ...StatisticsPdfBreakdown.section(
                  title: 'Gastos por categoría',
                  total: report.categorizedTotal,
                  breakdown: report.categorizedBreakdown,
                  data: data,
                  donutLabel: 'Total gastos',
                ),
              ],
            ],
            if (movements != null) ...[
              pw.NewPage(),
              ...StatisticsPdfMovements.section(movements, data),
            ],
          ];
        },
      ),
    );

    return doc.save();
  }
}
