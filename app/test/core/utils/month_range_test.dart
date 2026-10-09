import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/month_range.dart';

void main() {
  group('currentMonthRange', () {
    test('goes from the first day of the month to the given day', () {
      final range = currentMonthRange(DateTime(2026, 10, 9));

      expect(range.start, DateTime(2026, 10));
      expect(range.end, DateTime(2026, 10, 9));
    });

    test('drops the time of day', () {
      final range = currentMonthRange(DateTime(2026, 10, 9, 15, 30, 45));

      expect(range.end, DateTime(2026, 10, 9));
    });

    test('is a single day on the first of the month', () {
      final range = currentMonthRange(DateTime(2026, 3, 1, 23, 59));

      expect(range.start, range.end);
    });

    test('keeps the last day of a leap-year February', () {
      final range = currentMonthRange(DateTime(2028, 2, 29));

      expect(range.start, DateTime(2028, 2));
      expect(range.end, DateTime(2028, 2, 29));
    });

    test('defaults to the current month', () {
      final range = currentMonthRange();

      expect(range.start.day, 1);
      expect(range.end.month, range.start.month);
      expect(range.end.hour, 0);
    });
  });
}
