import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/app_clock.dart';

void main() {
  group('nowLocal', () {
    test('returns a local time close to the system clock', () {
      final before = DateTime.now();
      final now = nowLocal();
      final after = DateTime.now();

      expect(now.isUtc, isFalse);
      expect(now.isBefore(before), isFalse);
      expect(now.isAfter(after), isFalse);
    });
  });

  group('asLocal', () {
    test('converts a UTC value to local time keeping the same moment', () {
      final utc = DateTime.utc(2026, 10, 25, 12);
      final local = asLocal(utc);

      expect(local.isUtc, isFalse);
      expect(local.isAtSameMomentAs(utc), isTrue);
    });

    test('leaves a local value unchanged', () {
      final local = DateTime(2026, 10, 25, 12);

      expect(asLocal(local), local);
    });
  });
}
