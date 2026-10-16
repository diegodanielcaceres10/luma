import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/utils/currency_format.dart';

void main() {
  group('formatCurrency', () {
    test('uses Spanish separators and the currency code', () {
      final text = formatCurrency(2480.75, 'EUR');

      expect(text, contains('2.480,75'));
      expect(text, contains('EUR'));
    });

    test('groups thousands and rounds to two decimals', () {
      expect(formatCurrency(1234567.891, 'EUR'), contains('1.234.567,89'));
    });

    test('always shows two decimals', () {
      expect(formatCurrency(0, 'EUR'), contains('0,00'));
      expect(formatCurrency(5, 'EUR'), contains('5,00'));
    });

    test('keeps the sign of negative amounts', () {
      expect(formatCurrency(-12.5, 'EUR'), contains('-12,50'));
    });
  });

  group('currencySymbol', () {
    test('returns the code the formatter prints', () {
      expect(currencySymbol('EUR'), 'EUR');
    });
  });
}
