import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/invoices/data/models/invoice.dart';
import 'package:luma/features/notifications/domain/missing_invoice_rule.dart';
import 'package:luma/features/services/data/models/service.dart';

Service service({
  String id = 's1',
  int? dueDay = 15,
  bool isActive = true,
}) {
  return Service(
    id: id,
    name: 'Servicio $id',
    approximateAmount: 50,
    dueDay: dueDay,
    isActive: isActive,
  );
}

Invoice invoice({
  String serviceId = 's1',
  int month = 10,
  int year = 2026,
  bool paid = false,
  bool cancelled = false,
}) {
  return Invoice(
    id: 'i-$serviceId-$month-$year',
    serviceId: serviceId,
    month: month,
    year: year,
    amount: 50,
    paid: paid,
    cancelled: cancelled,
  );
}

List<String> missingIds({
  required List<Service> services,
  List<Invoice> invoices = const [],
  required DateTime today,
}) {
  return servicesMissingInvoiceToday(
    services: services,
    invoices: invoices,
    today: today,
  ).map((s) => s.id).toList();
}

void main() {
  group('servicesMissingInvoiceToday', () {
    final today = DateTime(2026, 10, 15, 9);

    test('returns nothing when there are no services', () {
      expect(missingIds(services: const [], today: today), isEmpty);
    });

    test('returns a service whose due day is today and has no invoice', () {
      expect(missingIds(services: [service()], today: today), ['s1']);
    });

    test('ignores services due on another day', () {
      final services = [service(dueDay: 14), service(id: 's2', dueDay: 16)];

      expect(missingIds(services: services, today: today), isEmpty);
    });

    test('ignores inactive services and services without a due day', () {
      final services = [
        service(isActive: false),
        service(id: 's2', dueDay: null),
      ];

      expect(missingIds(services: services, today: today), isEmpty);
    });

    test('keeps the order of the services it returns', () {
      final services = [
        service(id: 'b'),
        service(id: 'x', dueDay: 3),
        service(id: 'a'),
      ];

      expect(missingIds(services: services, today: today), ['b', 'a']);
    });

    group('with invoices', () {
      test('skips a service with a pending invoice this month', () {
        expect(
          missingIds(
            services: [service()],
            invoices: [invoice()],
            today: today,
          ),
          isEmpty,
        );
      });

      test('skips a service with a paid or a cancelled invoice this month', () {
        for (final existing in [
          invoice(paid: true),
          invoice(cancelled: true),
        ]) {
          expect(
            missingIds(
              services: [service()],
              invoices: [existing],
              today: today,
            ),
            isEmpty,
          );
        }
      });

      test('does not count an invoice from another month or year', () {
        final invoices = [
          invoice(month: 9),
          invoice(year: 2025),
        ];

        expect(
          missingIds(services: [service()], invoices: invoices, today: today),
          ['s1'],
        );
      });

      test('does not count an invoice of another service', () {
        expect(
          missingIds(
            services: [service()],
            invoices: [invoice(serviceId: 'otro')],
            today: today,
          ),
          ['s1'],
        );
      });

      test('only the service without an invoice is returned', () {
        final services = [service(id: 'a'), service(id: 'b')];

        expect(
          missingIds(
            services: services,
            invoices: [invoice(serviceId: 'a')],
            today: today,
          ),
          ['b'],
        );
      });
    });

    group('when the due day does not exist in the month', () {
      test('day 31 fires on the 30th of a 30-day month', () {
        final services = [service(dueDay: 31)];

        expect(
          missingIds(services: services, today: DateTime(2026, 4, 30)),
          ['s1'],
        );
        expect(
          missingIds(services: services, today: DateTime(2026, 4, 29)),
          isEmpty,
        );
      });

      test('days 29, 30 and 31 fire on 28 February in a normal year', () {
        final services = [
          service(id: 'd29', dueDay: 29),
          service(id: 'd30', dueDay: 30),
          service(id: 'd31', dueDay: 31),
        ];

        expect(
          missingIds(services: services, today: DateTime(2026, 2, 28)),
          ['d29', 'd30', 'd31'],
        );
        expect(
          missingIds(services: services, today: DateTime(2026, 2, 27)),
          isEmpty,
        );
      });

      test('days 30 and 31 fire on 29 February in a leap year', () {
        final services = [
          service(id: 'd29', dueDay: 29),
          service(id: 'd30', dueDay: 30),
          service(id: 'd31', dueDay: 31),
        ];

        expect(
          missingIds(services: services, today: DateTime(2028, 2, 29)),
          ['d29', 'd30', 'd31'],
        );
        expect(
          missingIds(services: services, today: DateTime(2028, 2, 28)),
          isEmpty,
        );
      });

      test('day 31 fires on 31 December', () {
        expect(
          missingIds(
            services: [service(dueDay: 31)],
            today: DateTime(2026, 12, 31),
          ),
          ['s1'],
        );
      });
    });
  });
}
