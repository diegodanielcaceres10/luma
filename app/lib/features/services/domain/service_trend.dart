import '../../invoices/data/models/invoice.dart';

/// Number of months shown in the service trend, current month included.
const int kServiceTrendMonths = 3;

class ServiceMonth {
  /// First day of the month.
  final DateTime month;

  /// Invoice amount for the period; null when the service has no
  /// (non-cancelled) invoice for it.
  final double? amount;

  const ServiceMonth({required this.month, required this.amount});
}

class ServiceTrend {
  /// Oldest first; the last item is the current month.
  final List<ServiceMonth> months;

  /// Average of the invoices that exist in the window.
  final double? average;

  /// Latest invoice versus the one before it. Null with fewer than two
  /// invoices or when the earlier one is zero.
  final double? changePercent;

  const ServiceTrend({
    required this.months,
    required this.average,
    required this.changePercent,
  });

  bool get isEmpty => months.every((m) => m.amount == null);
}

/// Builds the trend from a service's invoices, by invoice period (month and
/// year), ignoring cancelled ones.
ServiceTrend buildServiceTrend({
  required String serviceId,
  required List<Invoice> invoices,
  required DateTime today,
}) {
  final start =
      DateTime(today.year, today.month - (kServiceTrendMonths - 1), 1);

  final months = <ServiceMonth>[];
  for (var i = 0; i < kServiceTrendMonths; i++) {
    final month = DateTime(start.year, start.month + i, 1);
    double? amount;
    for (final invoice in invoices) {
      if (invoice.serviceId != serviceId ||
          invoice.cancelled ||
          invoice.month != month.month ||
          invoice.year != month.year) {
        continue;
      }
      amount = (amount ?? 0) + invoice.amount;
    }
    months.add(ServiceMonth(month: month, amount: amount));
  }

  final amounts = [
    for (final month in months)
      if (month.amount != null) month.amount!,
  ];

  final average = amounts.isEmpty
      ? null
      : amounts.fold<double>(0, (sum, value) => sum + value) / amounts.length;

  double? change;
  if (amounts.length >= 2) {
    final latest = amounts[amounts.length - 1];
    final previous = amounts[amounts.length - 2];
    if (previous != 0) change = (latest - previous) / previous * 100;
  }

  return ServiceTrend(
    months: months,
    average: average,
    changePercent: change,
  );
}
