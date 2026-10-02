import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/monthly_bar_chart.dart';
import '../../../../core/widgets/trend_card.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../data/models/service.dart';
import '../../domain/service_trend.dart';

/// Last-3-months invoices of a service, with its approximate amount as a
/// dashed reference line. Reads the invoices already loaded in
/// [InvoiceViewModel]; the parent rebuilds it when they change.
class ServiceTrendSection extends StatelessWidget {
  final Service service;
  final String currency;
  final Color color;
  final InvoiceViewModel invoiceViewModel;

  const ServiceTrendSection({
    super.key,
    required this.service,
    required this.currency,
    required this.color,
    required this.invoiceViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return TrendCard(
      title: 'Últimos 3 meses',
      child: _content(),
    );
  }

  Widget _content() {
    if (!invoiceViewModel.hasLoaded) {
      if (invoiceViewModel.isLoading) {
        return const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.authAccent),
          ),
        );
      }
      return const Text(
        'No se pudieron cargar las facturas.',
        style: TextStyle(fontSize: 14, color: AppColors.authTextSecondary),
      );
    }

    final trend = buildServiceTrend(
      serviceId: service.id,
      invoices: invoiceViewModel.invoices,
      today: nowLocal(),
    );

    if (trend.isEmpty) {
      return const Text(
        'Sin facturas en los últimos 3 meses.',
        style: TextStyle(fontSize: 14, color: AppColors.authTextSecondary),
      );
    }

    final average = trend.average;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonthlyBarChart(
          bars: [
            for (final month in trend.months)
              MonthlyBar(month: month.month, value: month.amount),
          ],
          currency: currency,
          color: color,
          referenceValue: service.approximateAmount,
          referenceLabel: 'Monto aproximado',
          missingLabel: 'Sin factura',
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.authCardBorder),
        TrendSummaryRow(
          label: 'Promedio de las facturas',
          value: Text(
            average == null ? '—' : formatCurrency(average, currency),
            style: trendValueStyle,
          ),
        ),
        const Divider(height: 1, color: AppColors.authCardBorder),
        TrendSummaryRow(
          label: 'Última factura vs. la anterior',
          // Paying more for a service is always bad news.
          value: TrendChangeValue(
            percent: trend.changePercent,
            risingIsGood: false,
          ),
        ),
      ],
    );
  }
}
