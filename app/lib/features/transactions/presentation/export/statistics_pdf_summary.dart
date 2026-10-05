import 'package:pdf/widgets.dart' as pw;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../view_models/transactions_statistics_report.dart';
import 'statistics_pdf_style.dart';
import 'transactions_statistics_pdf_data.dart';

/// Header, key figures and uncontrolled-spending card of the statistics PDF.
class StatisticsPdfSummary {
  StatisticsPdfSummary._();

  static pw.Widget header(
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
                color: pdfColor(AppColors.authAccentDark),
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
            color: kPdfTextPrimary,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          data.monthLabel,
          style: const pw.TextStyle(fontSize: 14, color: kPdfTextSecondary),
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1, color: kPdfBorder),
      ],
    );
  }

  static pw.Widget summaryRow(TransactionsStatisticsScreenPdfData data) {
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
        color: kPdfCardFill,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: kPdfBorder, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: kPdfTextSecondary),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            formatCurrency(amount, currency),
            style: const pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: kPdfTextPrimary,
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
                color: pdfColor(
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

  static pw.Widget uncontrolledCard(
    TransactionsStatisticsReport report,
    String currency,
  ) {
    final tone = pdfColor(
      report.isUncontrolledExpense
          ? AppColors.authExpense
          : AppColors.authIncome,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: kPdfCardFill,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: kPdfBorder, width: 0.8),
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
                    color: kPdfTextPrimary,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  report.isUncontrolledExpense
                      ? 'Gasto no controlado este mes'
                      : 'Ingreso no controlado este mes',
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: kPdfTextSecondary,
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
}
