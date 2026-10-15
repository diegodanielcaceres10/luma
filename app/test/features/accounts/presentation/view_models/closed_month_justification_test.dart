import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/account.dart';
import 'package:luma/features/accounts/data/models/monthly_opening_balance.dart';
import 'package:luma/features/accounts/presentation/view_models/closed_month_justification.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';

Account account(String id, {DateTime? createdAt}) => Account(
      id: id,
      name: id,
      balance: 0,
      isActive: true,
      balanceUpdatedAt: DateTime(2026, 10, 1),
      createdAt: createdAt,
    );

TransactionEntry entry(String accountId) => TransactionEntry(
      id: 't-$accountId',
      type: 'expense',
      amount: 10,
      date: DateTime(2026, 8, 5),
      category: const TransactionCategory(name: 'Comida'),
      account: TransactionAccount(id: accountId, name: accountId),
    );

void main() {
  group('eligibleAccounts', () {
    final august = DateTime(2026, 8);
    final now = DateTime(2026, 10, 14);

    final june = DateTime(2026, 6, 12);

    List<Account> eligible({
      Map<String, Set<int>> openingMonths = const {},
      List<TransactionEntry> entries = const [],
      List<Account>? accounts,
      DateTime? month,
    }) {
      return ClosedMonthJustification.eligibleAccounts(
        month: month ?? august,
        activeAccounts: accounts ?? [account('a', createdAt: june)],
        openingMonthsByAccount: openingMonths,
        monthEntries: entries,
        now: now,
      );
    }

    test('offers an account that existed then and has nothing in the month',
        () {
      final result = eligible(openingMonths: {
        'a': {monthIndex(2026, 6), monthIndex(2026, 10)},
      });

      expect(result.map((a) => a.id), ['a']);
    });

    test('offers an account that never had an opening balance', () {
      expect(eligible().map((a) => a.id), ['a']);
    });

    test('offers an account created during that same month', () {
      final result = eligible(
        accounts: [account('a', createdAt: DateTime(2026, 8, 31))],
      );

      expect(result.map((a) => a.id), ['a']);
    });

    test('offers an account whose creation date is unknown', () {
      final result = eligible(accounts: [account('a')]);

      expect(result.map((a) => a.id), ['a']);
    });

    test('skips an account that already has an opening balance that month',
        () {
      final result = eligible(openingMonths: {
        'a': {monthIndex(2026, 6), monthIndex(2026, 8)},
      });

      expect(result, isEmpty);
    });

    test('skips an account with movements in the month', () {
      final result = eligible(entries: [entry('a')]);

      expect(result, isEmpty);
    });

    test('keeps an account when only another account has movements', () {
      final result = eligible(
        accounts: [
          account('a', createdAt: june),
          account('b', createdAt: june),
        ],
        entries: [entry('a')],
      );

      expect(result.map((a) => a.id), ['b']);
    });

    test('skips an account created after the month', () {
      final result = eligible(
        accounts: [account('a', createdAt: DateTime(2026, 9, 1))],
      );

      expect(result, isEmpty);
    });

    test('offers nothing for the current or a future month', () {
      expect(eligible(month: DateTime(2026, 10)), isEmpty);
      expect(eligible(month: DateTime(2026, 11)), isEmpty);
    });

    test('keeps the order of the accounts', () {
      final result = eligible(
        accounts: [
          account('b', createdAt: june),
          account('a', createdAt: june),
        ],
      );

      expect(result.map((a) => a.id), ['b', 'a']);
    });
  });

  group('difference', () {
    test('is the closing balance minus the opening balance', () {
      expect(
        ClosedMonthJustification.difference(
          openingBalance: 100,
          closingBalance: 160,
        ),
        60,
      );
      expect(
        ClosedMonthJustification.difference(
          openingBalance: 100,
          closingBalance: 70,
        ),
        -30,
      );
    });

    test('is rounded to cents', () {
      expect(
        ClosedMonthJustification.difference(
          openingBalance: 0.1,
          closingBalance: 0.3,
        ),
        0.2,
      );
    });
  });

  group('unjustifiedRemainder', () {
    test('is what the movements do not cover', () {
      expect(
        ClosedMonthJustification.unjustifiedRemainder(
          difference: 50,
          movementsTotal: 30,
        ),
        20,
      );
      expect(
        ClosedMonthJustification.unjustifiedRemainder(
          difference: -40,
          movementsTotal: -10,
        ),
        -30,
      );
    });

    test('is zero when the movements cover the whole difference', () {
      expect(
        ClosedMonthJustification.unjustifiedRemainder(
          difference: 50,
          movementsTotal: 50,
        ),
        0,
      );
    });

    test('is rounded to cents', () {
      expect(
        ClosedMonthJustification.unjustifiedRemainder(
          difference: 0.3,
          movementsTotal: 0.1,
        ),
        0.2,
      );
    });
  });
}
