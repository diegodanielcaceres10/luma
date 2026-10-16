import 'package:pdf/widgets.dart' as pw;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
import '../../data/models/transaction_entry.dart' show TransactionEntry;
import 'statistics_pdf_style.dart';
import 'transactions_statistics_pdf_data.dart';

/// Table of the month's movements of the extended statistics PDF.
class StatisticsPdfMovements {
  StatisticsPdfMovements._();

  /// Title and table of the month's movements, same order as the app.
  static List<pw.Widget> section(
    List<TransactionEntry> movements,
    TransactionsStatisticsScreenPdfData data,
  ) {
    final count = movements.length;

    return [
      pw.Text(
        'Movimientos',
        style: const pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: kPdfTextPrimary,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        count == 0
            ? 'No hay movimientos registrados en '
                '${data.monthLabel.toLowerCase()}.'
            : '$count ${count == 1 ? 'movimiento' : 'movimientos'} en '
                '${data.monthLabel.toLowerCase()}',
        style: const pw.TextStyle(fontSize: 10, color: kPdfTextSecondary),
      ),
      if (count > 0) ...[
        pw.SizedBox(height: 12),
        _movementsTable(movements, data.currency),
      ],
    ];
  }

  static pw.Widget _movementsTable(
    List<TransactionEntry> movements,
    String currency,
  ) {
    const headerStyle = pw.TextStyle(
      fontSize: 8.5,
      fontWeight: pw.FontWeight.bold,
      color: kPdfTextSecondary,
    );

    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FixedColumnWidth(56),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FixedColumnWidth(92),
      },
      children: [
        // The header repeats on every page the table spans.
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: kPdfBorder, width: 0.8),
            ),
          ),
          children: [
            _tableCell('Fecha', style: headerStyle),
            _tableCell('Descripción', style: headerStyle),
            _tableCell('Categoría', style: headerStyle),
            _tableCell('Cuenta', style: headerStyle),
            _tableCell(
              'Importe',
              style: headerStyle,
              align: pw.TextAlign.right,
            ),
          ],
        ),
        for (final movement in movements) _movementRow(movement, currency),
      ],
    );
  }

  static pw.TableRow _movementRow(TransactionEntry movement, String currency) {
    final description = movement.description?.trim() ?? '';
    final sign = movement.isIncome ? '+' : '-';
    // Transfers are neither income nor expense, so they get a neutral color.
    final amountColor = movement.isTransfer
        ? kPdfTransferColor
        : pdfColor(
            movement.isIncome
                ? AppColors.authAccentDark
                : AppColors.authExpense,
          );

    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: kPdfBorder, width: 0.5),
        ),
      ),
      children: [
        _tableCell(
          formatDate(movement.date),
          style: const pw.TextStyle(fontSize: 9, color: kPdfTextSecondary),
        ),
        _tableCell(
          description.isNotEmpty ? description : movement.category.name,
          style: const pw.TextStyle(fontSize: 9.5, color: kPdfTextPrimary),
          maxLines: 2,
        ),
        _tableCell(
          movement.isTransfer ? 'Transferencia' : movement.category.name,
          style: pw.TextStyle(
            fontSize: 9,
            color: movement.isTransfer ? kPdfTransferColor : kPdfTextSecondary,
          ),
        ),
        _tableCell(
          movement.account.name,
          style: const pw.TextStyle(fontSize: 9, color: kPdfTextSecondary),
        ),
        _tableCell(
          '$sign${formatCurrency(movement.amount, currency)}',
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: amountColor,
          ),
          align: pw.TextAlign.right,
        ),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    required pw.TextStyle style,
    pw.TextAlign align = pw.TextAlign.left,
    int maxLines = 1,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        maxLines: maxLines,
        textAlign: align,
        style: style,
      ),
    );
  }
}
