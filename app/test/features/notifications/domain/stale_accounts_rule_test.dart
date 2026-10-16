import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/account.dart';
import 'package:luma/features/notifications/domain/stale_accounts_rule.dart';

Account account({
  String id = 'a1',
  bool isActive = true,
  required DateTime updatedAt,
}) {
  return Account(
    id: id,
    name: 'Cuenta $id',
    balance: 100,
    isActive: isActive,
    balanceUpdatedAt: updatedAt,
  );
}

void main() {
  group('staleAccounts', () {
    final today = DateTime(2026, 10, 10, 9);

    test('the default threshold is five days', () {
      expect(kStaleAccountDays, 5);
    });

    test('returns nothing when there are no accounts', () {
      expect(staleAccounts(accounts: const [], today: today), isEmpty);
    });

    test('reports an account updated exactly five days ago', () {
      final result = staleAccounts(
        accounts: [account(updatedAt: DateTime(2026, 10, 5, 9))],
        today: today,
      );

      expect(result, hasLength(1));
      expect(result.single.account.id, 'a1');
      expect(result.single.days, 5);
    });

    test('does not report an account updated four days ago', () {
      final result = staleAccounts(
        accounts: [account(updatedAt: DateTime(2026, 10, 6, 9))],
        today: today,
      );

      expect(result, isEmpty);
    });

    test('keeps reporting it every day with the growing count', () {
      final accounts = [account(updatedAt: DateTime(2026, 10, 5))];

      expect(
        staleAccounts(accounts: accounts, today: DateTime(2026, 10, 6)),
        isEmpty,
      );
      expect(
        staleAccounts(accounts: accounts, today: DateTime(2026, 10, 10))
            .single
            .days,
        5,
      );
      expect(
        staleAccounts(accounts: accounts, today: DateTime(2026, 10, 14))
            .single
            .days,
        9,
      );
    });

    test('counts calendar days, not blocks of 24 hours', () {
      // 4 days and 2 minutes apart, but 5 calendar days.
      final late = account(updatedAt: DateTime(2026, 10, 5, 23, 59));
      final shortlyAfterMidnight = DateTime(2026, 10, 10, 0, 1);

      expect(
        staleAccounts(accounts: [late], today: shortlyAfterMidnight)
            .single
            .days,
        5,
      );

      // 5 days and 23 hours apart, still 5 calendar days.
      final early = account(updatedAt: DateTime(2026, 10, 5, 0, 1));
      final almostMidnight = DateTime(2026, 10, 10, 23, 59);

      expect(
        staleAccounts(accounts: [early], today: almostMidnight).single.days,
        5,
      );
    });

    test('is not thrown off by the clock changes', () {
      // Autumn: clocks go back on 25 October 2026 in Europe.
      final autumn = staleAccounts(
        accounts: [account(updatedAt: DateTime(2026, 10, 21, 12))],
        today: DateTime(2026, 10, 26, 12),
      );
      // Spring: clocks go forward on 29 March 2026 in Europe.
      final spring = staleAccounts(
        accounts: [account(updatedAt: DateTime(2026, 3, 25, 12))],
        today: DateTime(2026, 3, 30, 12),
      );

      expect(autumn.single.days, 5);
      expect(spring.single.days, 5);
    });

    test('skips inactive accounts', () {
      final result = staleAccounts(
        accounts: [
          account(isActive: false, updatedAt: DateTime(2026, 1, 1)),
        ],
        today: today,
      );

      expect(result, isEmpty);
    });

    test('never reports an account updated today or in the future', () {
      final result = staleAccounts(
        accounts: [
          account(id: 'today', updatedAt: DateTime(2026, 10, 10, 8)),
          account(id: 'future', updatedAt: DateTime(2026, 10, 12)),
        ],
        today: today,
      );

      expect(result, isEmpty);
    });

    test('honors a custom threshold', () {
      final accounts = [account(updatedAt: DateTime(2026, 10, 9))];

      expect(
        staleAccounts(accounts: accounts, today: today, minDays: 1)
            .single
            .days,
        1,
      );
      expect(staleAccounts(accounts: accounts, today: today), isEmpty);
    });

    test('a threshold of zero also reports accounts updated today', () {
      final result = staleAccounts(
        accounts: [account(updatedAt: DateTime(2026, 10, 10, 8))],
        today: today,
        minDays: 0,
      );

      expect(result.single.days, 0);
    });

    test('returns only the stale accounts, in the given order', () {
      final result = staleAccounts(
        accounts: [
          account(id: 'old', updatedAt: DateTime(2026, 9, 1)),
          account(id: 'fresh', updatedAt: DateTime(2026, 10, 9)),
          account(id: 'edge', updatedAt: DateTime(2026, 10, 5)),
        ],
        today: today,
      );

      expect(result.map((r) => r.account.id), ['old', 'edge']);
      expect(result.map((r) => r.days), [39, 5]);
    });
  });
}
