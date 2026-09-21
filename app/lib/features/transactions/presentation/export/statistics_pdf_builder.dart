import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../view_models/transaction_view_model.dart';

/// Foto de lo que muestra Estadísticas para un mes, lista para volcar a un
/// PDF. Se arma con los valores del [TransactionViewModel] en el momento de
/// exportar, así el PDF no cambia si el usuario cambia de mes mientras se
/// genera.
class StatisticsPdfData {
  /// Primer día del mes exportado.
  final DateTime month;

  /// 'Agosto 2026'.
  final String monthLabel;
  final String currency;
  final double income;
  final double expenses;
  final double netResult;
  final double? incomeChangePercent;
  final double? expenseChangePercent;
  final double? netChangePercent;
  final List<CategoryTotal> breakdown;
  final int uncategorizedCount;
  final double uncategorizedTotal;

  const StatisticsPdfData({
    required this.month,
    required this.monthLabel,
    required this.currency,
    required this.income,
    required this.expenses,
    required this.netResult,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
    required this.netChangePercent,
    required this.breakdown,
    required this.uncategorizedCount,
    required this.uncategorizedTotal,
  });

  /// 'luma-estadisticas-2026-08.pdf'.
  String get fileName =>
      'luma-estadisticas-${month.year}-${month.month.toString().padLeft(2, '0')}.pdf';
}

/// Arma el PDF de Estadísticas de un mes ya cerrado.
///
/// Usa las fuentes Roboto de `assets/fonts`: las fuentes estándar del PDF
/// (Helvetica) no tienen el símbolo € ni todos los acentos.
class StatisticsPdfBuilder {
  StatisticsPdfBuilder._();

  // Colores pensados para papel (fondo blanco), no los del tema oscuro.
  static const _textPrimary = PdfColor.fromInt(0xFF111827);
  static const _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _cardFill = PdfColor.fromInt(0xFFF9FAFB);

  static PdfColor _pdfColor(Color color) => PdfColor.fromInt(color.toARGB32());

  static Future<Uint8List> build(StatisticsPdfData data) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );

    final generatedOn = DateFormat('d MMMM yyyy', 'es').format(DateTime.now());

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
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generado con Luma · $generatedOn',
                style: const pw.TextStyle(fontSize: 9, color: _textSecondary),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: _textSecondary),
              ),
            ],
          ),
        ),
        build: (context) => [
          _header(data),
          pw.SizedBox(height: 22),
          _summaryRow(data),
          pw.SizedBox(height: 26),
          ..._expensesByCategory(data),
          if (data.uncategorizedCount > 0) ...[
            pw.SizedBox(height: 22),
            _uncategorizedNote(data),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(StatisticsPdfData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Luma',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _pdfColor(AppColors.authAccentDark),
          ),
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

  static pw.Widget _summaryRow(StatisticsPdfData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _summaryCard(
            label: 'Ingresos',
            amount: data.income,
            currency: data.currency,
            changePercent: data.incomeChangePercent,
            // Más ingresos es una mejora.
            isFavorable: (p) => p >= 0,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _summaryCard(
            label: 'Gastos',
            amount: data.expenses,
            currency: data.currency,
            changePercent: data.expenseChangePercent,
            // Acá es al revés: gastar menos que el mes anterior es la mejora.
            isFavorable: (p) => p <= 0,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _summaryCard(
            label: 'Balance del mes',
            amount: data.netResult,
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

  /// Título, total, barra apilada con el peso de cada categoría y una fila
  /// por categoría. Cada fila es un widget suelto de la lista de la página
  /// (no una sola tabla) para que el PDF pueda cortar entre páginas si hay
  /// muchas categorías.
  static List<pw.Widget> _expensesByCategory(StatisticsPdfData data) {
    final title = pw.Text(
      'Gastos por categoría',
      style: const pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: _textPrimary,
      ),
    );

    if (data.breakdown.isEmpty) {
      return [
        title,
        pw.SizedBox(height: 10),
        pw.Text(
          'No hay gastos registrados en ${data.monthLabel.toLowerCase()}.',
          style: const pw.TextStyle(fontSize: 11, color: _textSecondary),
        ),
      ];
    }

    return [
      title,
      pw.SizedBox(height: 4),
      pw.Text(
        formatCurrency(data.expenses, data.currency),
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
      _stackedBar(data.breakdown),
      pw.SizedBox(height: 10),
      for (final item in data.breakdown) _categoryRow(item, data.currency),
    ];
  }

  static PdfColor _categoryColor(CategoryTotal item) => _pdfColor(
        colorFromHex(item.category.color, fallback: AppColors.authAccent),
      );

  /// Barra horizontal dividida en segmentos proporcionales al % de cada
  /// categoría, con el mismo color que en la app.
  static pw.Widget _stackedBar(List<CategoryTotal> breakdown) {
    final segments = breakdown.where((item) => item.percent > 0).toList();

    return pw.SizedBox(
      height: 12,
      child: pw.Row(
        children: [
          for (final item in segments)
            pw.Expanded(
              // flex debe ser entero: se usa el % con dos decimales de
              // precisión y mínimo 1 para que ninguna categoría desaparezca.
              flex: (item.percent * 100).round().clamp(1, 1000000),
              child: pw.Container(color: _categoryColor(item)),
            ),
        ],
      ),
    );
  }

  static pw.Widget _categoryRow(CategoryTotal item, String currency) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _border, width: 0.6),
        ),
      ),
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
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              formatCurrency(item.amount, currency),
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 11, color: _textPrimary),
            ),
          ),
          pw.SizedBox(
            width: 42,
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

  static pw.Widget _uncategorizedNote(StatisticsPdfData data) {
    final count = data.uncategorizedCount;

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
                  'Sin categoría',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  count == 1 ? '1 movimiento' : '$count movimientos',
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            formatCurrency(data.uncategorizedTotal, data.currency),
            style: const pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
