import '../../invoices/data/models/invoice.dart';
import '../../services/data/models/service.dart';

/// Active services whose due day is [today] and that have no invoice
/// (pending, paid or cancelled) for the current month/year.
///
/// When a service's due day does not exist in the current month (e.g. 31 in
/// a 30-day month), it fires on the last day of that month.
List<Service> servicesMissingInvoiceToday({
  required List<Service> services,
  required List<Invoice> invoices,
  required DateTime today,
}) {
  final lastDayOfMonth = DateTime(today.year, today.month + 1, 0).day;

  final servicesWithInvoice = {
    for (final invoice in invoices)
      if (invoice.month == today.month && invoice.year == today.year)
        invoice.serviceId,
  };

  return services.where((service) {
    final dueDay = service.dueDay;
    if (!service.isActive || dueDay == null) return false;

    final effectiveDueDay = dueDay > lastDayOfMonth ? lastDayOfMonth : dueDay;
    return effectiveDueDay == today.day &&
        !servicesWithInvoice.contains(service.id);
  }).toList();
}
