import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';

void main() {
  group('TransactionCategory.fromMap', () {
    test('falls back to "Sin categoría" when the map is null', () {
      final category = TransactionCategory.fromMap(null);

      expect(category.name, 'Sin categoría');
      expect(category.id, isNull);
      expect(category.color, isNull);
    });

    test('falls back to "Sin categoría" when the name is missing', () {
      expect(TransactionCategory.fromMap({'id': 'c1'}).name, 'Sin categoría');
    });

    test('reads id, name and color', () {
      final category = TransactionCategory.fromMap(
        {'id': 'c1', 'name': 'Comida', 'color': '#FF0000'},
      );

      expect(category.id, 'c1');
      expect(category.name, 'Comida');
      expect(category.color, '#FF0000');
    });
  });

  group('TransactionAccount.fromMap', () {
    test('falls back to "Sin cuenta" when the map is null', () {
      final account = TransactionAccount.fromMap(null);

      expect(account.name, 'Sin cuenta');
      expect(account.id, isNull);
    });

    test('falls back to "Sin cuenta" when the name is missing', () {
      expect(TransactionAccount.fromMap({'id': 'a1'}).name, 'Sin cuenta');
    });

    test('reads id, name and color', () {
      final account = TransactionAccount.fromMap(
        {'id': 'a1', 'name': 'Santander', 'color': '#00FF00'},
      );

      expect(account.id, 'a1');
      expect(account.name, 'Santander');
      expect(account.color, '#00FF00');
    });
  });

  group('TransactionEntry.fromMap', () {
    Map<String, dynamic> row({Map<String, dynamic>? overrides}) => {
          'id': 't1',
          'type': 'expense',
          'amount': 12,
          'description': 'Cena',
          'date': '2026-10-09',
          'categories': {'id': 'c1', 'name': 'Comida'},
          'accounts': {'id': 'a1', 'name': 'Santander'},
          'is_transfer': true,
          ...?overrides,
        };

    test('reads a full row', () {
      final entry = TransactionEntry.fromMap(row());

      expect(entry.id, 't1');
      expect(entry.type, 'expense');
      expect(entry.amount, 12.0);
      expect(entry.description, 'Cena');
      expect(entry.date, DateTime(2026, 10, 9));
      expect(entry.category.name, 'Comida');
      expect(entry.account.name, 'Santander');
      expect(entry.isTransfer, isTrue);
    });

    test('converts integer and decimal amounts to double', () {
      expect(TransactionEntry.fromMap(row()).amount, isA<double>());
      expect(
        TransactionEntry.fromMap(row(overrides: {'amount': 9.99})).amount,
        9.99,
      );
    });

    test('uses defaults when joins, description and flag are missing', () {
      final entry = TransactionEntry.fromMap({
        'id': 't2',
        'type': 'income',
        'amount': 100,
        'date': '2026-10-01',
      });

      expect(entry.description, isNull);
      expect(entry.category.name, 'Sin categoría');
      expect(entry.account.name, 'Sin cuenta');
      expect(entry.isTransfer, isFalse);
    });

    test('isIncome follows the type', () {
      expect(TransactionEntry.fromMap(row()).isIncome, isFalse);
      expect(
        TransactionEntry.fromMap(row(overrides: {'type': 'income'})).isIncome,
        isTrue,
      );
    });
  });
}
