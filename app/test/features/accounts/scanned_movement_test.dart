import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/scanned_movement.dart';

void main() {
  group('ScannedMovement.fromMap', () {
    test('parses a valid expense', () {
      final m = ScannedMovement.fromMap({
        'type': 'expense',
        'amount': 12.5,
        'date': '2026-10-01',
        'description': '  Mercadona ',
      });

      expect(m, isNotNull);
      expect(m!.type, 'expense');
      expect(m.amount, 12.5);
      expect(m.signedAmount, -12.5);
      expect(m.date, DateTime(2026, 10, 1));
      expect(m.description, 'Mercadona');
    });

    test('keeps income positive', () {
      final m = ScannedMovement.fromMap({'type': 'income', 'amount': 100});
      expect(m!.signedAmount, 100);
      expect(m.date, isNull);
      expect(m.description, isNull);
    });

    test('rounds the amount to cents', () {
      final m = ScannedMovement.fromMap({'type': 'income', 'amount': 10.006});
      expect(m!.amount, closeTo(10.01, 0.0001));
    });

    test('drops malformed entries', () {
      expect(ScannedMovement.fromMap(null), isNull);
      expect(ScannedMovement.fromMap('x'), isNull);
      expect(ScannedMovement.fromMap({'type': 'transfer', 'amount': 5}), isNull);
      expect(ScannedMovement.fromMap({'type': 'expense'}), isNull);
      expect(ScannedMovement.fromMap({'type': 'expense', 'amount': 0}), isNull);
      expect(ScannedMovement.fromMap({'type': 'expense', 'amount': -3}), isNull);
      expect(
        ScannedMovement.fromMap({'type': 'expense', 'amount': double.nan}),
        isNull,
      );
    });

    test('ignores an unparseable date and a blank description', () {
      final m = ScannedMovement.fromMap({
        'type': 'expense',
        'amount': 3,
        'date': 'ayer',
        'description': '   ',
      });
      expect(m!.date, isNull);
      expect(m.description, isNull);
    });
  });

  group('ScannedMovement.listFromResponse', () {
    test('keeps valid entries and skips the rest', () {
      final list = ScannedMovement.listFromResponse({
        'movements': [
          {'type': 'expense', 'amount': 5},
          {'type': 'bogus', 'amount': 5},
          {'type': 'income', 'amount': 7},
        ],
      });
      expect(list.map((m) => m.type), ['expense', 'income']);
    });

    test('returns empty for unexpected shapes', () {
      expect(ScannedMovement.listFromResponse(null), isEmpty);
      expect(ScannedMovement.listFromResponse({'movements': 'x'}), isEmpty);
      expect(ScannedMovement.listFromResponse({'error': 'boom'}), isEmpty);
    });
  });

  group('isPossibleDuplicate', () {
    final expense = ScannedMovement(
      type: 'expense',
      amount: 12.5,
      date: DateTime(2026, 10, 1),
    );

    test('matches same signed amount on the same day', () {
      expect(
        isPossibleDuplicate(expense, [(amount: -12.5, date: DateTime(2026, 10, 1, 18))]),
        isTrue,
      );
    });

    test('does not match opposite sign, other amount or other day', () {
      expect(
        isPossibleDuplicate(expense, [(amount: 12.5, date: DateTime(2026, 10, 1))]),
        isFalse,
      );
      expect(
        isPossibleDuplicate(expense, [(amount: -12.6, date: DateTime(2026, 10, 1))]),
        isFalse,
      );
      expect(
        isPossibleDuplicate(expense, [(amount: -12.5, date: DateTime(2026, 10, 2))]),
        isFalse,
      );
    });

    test('never flags a movement without date', () {
      const undated = ScannedMovement(type: 'expense', amount: 12.5);
      expect(
        isPossibleDuplicate(undated, [(amount: -12.5, date: DateTime(2026, 10, 1))]),
        isFalse,
      );
    });
  });
}
