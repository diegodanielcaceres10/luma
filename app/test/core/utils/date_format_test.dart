import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/date_format.dart';

void main() {
  group('formatDate', () {
    test('pads day and month', () {
      expect(formatDate(DateTime(2026, 10, 5)), '05/10/2026');
      expect(formatDate(DateTime(2026, 1, 31)), '31/01/2026');
    });
  });

  group('formatDateTime', () {
    test('adds hours and minutes', () {
      expect(
        formatDateTime(DateTime(2026, 10, 25, 14, 30)),
        '25/10/2026 14:30',
      );
    });

    test('uses a 24-hour clock', () {
      expect(formatDateTime(DateTime(2026, 10, 25, 0, 5)), '25/10/2026 00:05');
    });
  });

  group('formatDbDate', () {
    test('pads month and day', () {
      expect(formatDbDate(DateTime(2026, 1, 3)), '2026-01-03');
    });

    test('pads the year to four digits', () {
      expect(formatDbDate(DateTime(987, 1, 3)), '0987-01-03');
    });

    test('ignores the time of day', () {
      expect(formatDbDate(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
    });
  });
}
