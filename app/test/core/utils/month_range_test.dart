import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/month_range.dart';

void main() {
  test('spans from the first of the month to today', () {
    final range = currentMonthRange(DateTime(2026, 10, 17, 15, 30));
    expect(range.start, DateTime(2026, 10, 1));
    expect(range.end, DateTime(2026, 10, 17));
  });

  test('on the first day the range is that single day', () {
    final range = currentMonthRange(DateTime(2026, 10, 1, 9));
    expect(range.start, DateTime(2026, 10, 1));
    expect(range.end, DateTime(2026, 10, 1));
  });
}
