import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/app_clock.dart';
import 'package:luma/features/comparison/presentation/view_models/comparison_months.dart';

void main() {
  final now = nowLocal();
  final currentMonth = DateTime(now.year, now.month);
  final previousMonth = DateTime(now.year, now.month - 1);

  group('ComparisonMonths.fromQuery', () {
    test('defaults to the current month and the one before it', () {
      final months = ComparisonMonths.fromQuery();

      expect(months.after, currentMonth);
      expect(months.before, previousMonth);
    });

    test('from defaults to the month before to', () {
      final months = ComparisonMonths.fromQuery(to: '2026-03');

      expect(months.after, DateTime(2026, 3));
      expect(months.before, DateTime(2026, 2));
    });

    test('january defaults to december of the previous year', () {
      final months = ComparisonMonths.fromQuery(to: '2026-01');

      expect(months.before, DateTime(2025, 12));
    });

    test('explicit values are used', () {
      final months = ComparisonMonths.fromQuery(from: '2026-09', to: '2026-10');

      expect(months.before, DateTime(2026, 9));
      expect(months.after, DateTime(2026, 10));
    });

    test('an invalid to falls back to the current month', () {
      final months = ComparisonMonths.fromQuery(to: 'abc');

      expect(months.after, currentMonth);
      expect(months.before, previousMonth);
    });

    test('an invalid from falls back to the month before to', () {
      for (final from in ['abc', '2026-13', '2026-00', '26-09']) {
        final months = ComparisonMonths.fromQuery(from: from, to: '2026-03');

        expect(months.before, DateTime(2026, 2), reason: from);
      }
    });
  });

  group('ComparisonMonths.locationFor', () {
    test('omits to when it is the current month', () {
      final location = ComparisonMonths.locationFor(currentMonth);

      expect(location, startsWith('/statistics/compare?from='));
      expect(location, isNot(contains('to=')));
    });

    test('includes both months for a past month', () {
      expect(
        ComparisonMonths.locationFor(DateTime(2026, 3)),
        '/statistics/compare?from=2026-02&to=2026-03',
      );
    });

    test('crosses the year boundary', () {
      expect(
        ComparisonMonths.locationFor(DateTime(2026, 1)),
        '/statistics/compare?from=2025-12&to=2026-01',
      );
    });

    test('what it builds is read back to the same months', () {
      final month = DateTime(2025, 7);
      final uri = Uri.parse(ComparisonMonths.locationFor(month));

      final months = ComparisonMonths.fromQuery(
        from: uri.queryParameters['from'],
        to: uri.queryParameters['to'],
      );

      expect(months.after, month);
      expect(months.before, DateTime(2025, 6));
    });
  });
}
