import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/scanned_movement.dart';

void main() {
  group('ScannedMovement.fromMap', () {
    test('rejects values that are not a map', () {
      expect(ScannedMovement.fromMap(null), isNull);
      expect(ScannedMovement.fromMap('texto'), isNull);
      expect(ScannedMovement.fromMap(42), isNull);
      expect(ScannedMovement.fromMap(<Object>[]), isNull);
    });

    test('rejects a missing or unknown type', () {
      expect(ScannedMovement.fromMap({'amount': 10}), isNull);
      for (final type in ['transfer', 'EXPENSE', 7]) {
        expect(
          ScannedMovement.fromMap({'type': type, 'amount': 10}),
          isNull,
          reason: 'type: $type',
        );
      }
    });

    test('rejects amounts that are not a usable positive number', () {
      for (final amount in <Object?>[
        null,
        '12',
        0,
        -5,
        -0.01,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          ScannedMovement.fromMap({'type': 'expense', 'amount': amount}),
          isNull,
          reason: 'amount: $amount',
        );
      }
    });

    test('reads a valid movement', () {
      final movement = ScannedMovement.fromMap({
        'type': 'expense',
        'amount': 12.5,
        'date': '2026-10-09',
        'description': 'Mercadona',
      })!;

      expect(movement.type, 'expense');
      expect(movement.amount, 12.5);
      expect(movement.date, DateTime(2026, 10, 9));
      expect(movement.description, 'Mercadona');
    });

    test('accepts an integer amount', () {
      final movement =
          ScannedMovement.fromMap({'type': 'income', 'amount': 30})!;

      expect(movement.amount, 30.0);
    });

    test('rounds the amount to cents', () {
      expect(
        ScannedMovement.fromMap({'type': 'income', 'amount': 10.126})!.amount,
        10.13,
      );
      expect(
        ScannedMovement.fromMap({'type': 'income', 'amount': 10.124})!.amount,
        10.12,
      );
    });

    test('keeps the movement when the date is missing or unreadable', () {
      for (final date in <Object?>[null, 'no-es-fecha', 20261009]) {
        final movement = ScannedMovement.fromMap(
          {'type': 'income', 'amount': 5, 'date': date},
        );

        expect(movement, isNotNull, reason: 'date: $date');
        expect(movement!.date, isNull, reason: 'date: $date');
      }
    });

    test('trims the description and drops blank or non-text ones', () {
      ScannedMovement? read(Object? description) => ScannedMovement.fromMap(
            {'type': 'income', 'amount': 5, 'description': description},
          );

      expect(read('  Nómina  ')!.description, 'Nómina');
      expect(read('   ')!.description, isNull);
      expect(read('')!.description, isNull);
      expect(read(7)!.description, isNull);
      expect(read(null)!.description, isNull);
    });
  });

  group('ScannedMovement', () {
    test('signedAmount is negative for expenses and positive for income', () {
      const expense = ScannedMovement(type: 'expense', amount: 12.5);
      const income = ScannedMovement(type: 'income', amount: 12.5);

      expect(expense.signedAmount, -12.5);
      expect(income.signedAmount, 12.5);
    });

    test('copyWith overrides only the given fields', () {
      final original = ScannedMovement(
        type: 'expense',
        amount: 10,
        date: DateTime(2026, 10, 9),
        description: 'Café',
      );

      final copy = original.copyWith(amount: 12, description: 'Cena');

      expect(copy.type, 'expense');
      expect(copy.amount, 12);
      expect(copy.date, DateTime(2026, 10, 9));
      expect(copy.description, 'Cena');
    });
  });

  group('ScannedMovement.listFromResponse', () {
    test('returns an empty list when the response has no movements list', () {
      expect(ScannedMovement.listFromResponse(null), isEmpty);
      expect(ScannedMovement.listFromResponse('texto'), isEmpty);
      expect(ScannedMovement.listFromResponse(<String, Object>{}), isEmpty);
      expect(
        ScannedMovement.listFromResponse({'movements': 'texto'}),
        isEmpty,
      );
    });

    test('drops malformed entries and keeps the order of the rest', () {
      final movements = ScannedMovement.listFromResponse({
        'movements': [
          {'type': 'expense', 'amount': 1},
          'basura',
          {'type': 'income', 'amount': -3},
          {'type': 'income', 'amount': 2},
          null,
        ],
      });

      expect(movements.map((m) => m.amount), [1.0, 2.0]);
      expect(movements.map((m) => m.type), ['expense', 'income']);
    });
  });

  group('isPossibleDuplicate', () {
    final movement = ScannedMovement(
      type: 'expense',
      amount: 12.5,
      date: DateTime(2026, 10, 9),
    );

    test('matches on amount and calendar day, ignoring the time', () {
      expect(
        isPossibleDuplicate(
          movement,
          [(amount: -12.5, date: DateTime(2026, 10, 9, 18, 45))],
        ),
        isTrue,
      );
    });

    test('compares amounts to the cent', () {
      expect(
        isPossibleDuplicate(
          movement,
          [(amount: -12.499999, date: DateTime(2026, 10, 9))],
        ),
        isTrue,
      );
      expect(
        isPossibleDuplicate(
          movement,
          [(amount: -12.51, date: DateTime(2026, 10, 9))],
        ),
        isFalse,
      );
    });

    test('does not match an amount with the opposite sign', () {
      expect(
        isPossibleDuplicate(
          movement,
          [(amount: 12.5, date: DateTime(2026, 10, 9))],
        ),
        isFalse,
      );
    });

    test('does not match a different day', () {
      expect(
        isPossibleDuplicate(
          movement,
          [(amount: -12.5, date: DateTime(2026, 10, 10))],
        ),
        isFalse,
      );
    });

    test('never flags a movement without a date', () {
      const undated = ScannedMovement(type: 'expense', amount: 12.5);

      expect(
        isPossibleDuplicate(
          undated,
          [(amount: -12.5, date: DateTime(2026, 10, 9))],
        ),
        isFalse,
      );
    });

    test('is false when there is nothing to compare with', () {
      expect(isPossibleDuplicate(movement, const []), isFalse);
    });
  });

  group('typeFromAmountText', () {
    test('is expense only when the text starts with a minus sign', () {
      expect(typeFromAmountText('-5'), 'expense');
      expect(typeFromAmountText('  -5,50'), 'expense');
      expect(typeFromAmountText('5'), 'income');
      expect(typeFromAmountText(''), 'income');
    });
  });

  group('parseSignedAmount', () {
    test('accepts dot or comma as decimal separator', () {
      expect(parseSignedAmount('12,5'), 12.5);
      expect(parseSignedAmount('12.5'), 12.5);
    });

    test('keeps the sign and ignores surrounding spaces', () {
      expect(parseSignedAmount('-12.50'), -12.5);
      expect(parseSignedAmount('  3 '), 3.0);
    });

    test('returns null for text that is not a finite number', () {
      for (final text in ['', '  ', 'abc', 'NaN', 'Infinity', '-Infinity']) {
        expect(parseSignedAmount(text), isNull, reason: 'text: "$text"');
      }
    });
  });
}
