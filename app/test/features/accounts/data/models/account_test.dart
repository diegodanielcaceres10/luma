import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/account.dart';

Map<String, dynamic> row({String? createdAt}) => {
      'id': 'a',
      'name': 'Cuenta 1',
      'balance': 100,
      'is_active': true,
      'balance_updated_at': '2026-10-01T10:00:00Z',
      if (createdAt != null) 'created_at': createdAt,
    };

void main() {
  group('Account.fromMap', () {
    test('reads the creation date', () {
      final account = Account.fromMap(row(createdAt: '2026-06-12T08:30:00Z'));

      expect(account.createdAt, isNotNull);
      expect(
        account.createdAt!.toUtc(),
        DateTime.utc(2026, 6, 12, 8, 30),
      );
    });

    test('leaves the creation date empty when the row has none', () {
      final account = Account.fromMap(row());

      expect(account.createdAt, isNull);
    });
  });
}
