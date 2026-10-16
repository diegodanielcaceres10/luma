import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/month_filter_button.dart';
import '../../../../../core/widgets/screen_header.dart';

class StatisticsHeader extends StatelessWidget {
  final DateTime selectedMonth;

  final ValueChanged<DateTime> onMonthChanged;

  /// Null hides the "Exportar PDF" button.
  final VoidCallback? onExportPdf;

  /// Null hides the "Exportar PDF completo" button (summary and movements).
  final VoidCallback? onExportFullPdf;
  final bool isExportingPdf;
  final bool isExportingFullPdf;

  const StatisticsHeader({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
    this.onExportPdf,
    this.onExportFullPdf,
    this.isExportingPdf = false,
    this.isExportingFullPdf = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenHeader(
          title: 'Estadísticas',
          subtitle:
              'Analiza tus ingresos, gastos y mantén el control de tus finanzas.',
          action: MonthFilterButton(
            selectedMonth: selectedMonth,
            onChanged: onMonthChanged,
          ),
        ),
        if (onExportPdf != null || onExportFullPdf != null) ...[
          const SizedBox(height: 14),
          // Both buttons are disabled while either export is running.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onExportPdf != null)
                _ExportPdfButton(
                  label: 'Exportar PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  isLoading: isExportingPdf,
                  onPressed:
                      isExportingPdf || isExportingFullPdf ? null : onExportPdf,
                ),
              if (onExportFullPdf != null)
                _ExportPdfButton(
                  label: 'Exportar PDF completo',
                  icon: Icons.description_outlined,
                  isLoading: isExportingFullPdf,
                  onPressed: isExportingPdf || isExportingFullPdf
                      ? null
                      : onExportFullPdf,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ExportPdfButton extends StatelessWidget {
  final String label;

  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ExportPdfButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.authAccent,
        side: const BorderSide(color: AppColors.authCardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: onPressed,
      // The label stays in the tree (hidden) so the button keeps its size
      // while only the spinner is visible.
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: isLoading ? 0 : 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.authAccent,
              ),
            ),
        ],
      ),
    );
  }
}
