import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/presentation/view_models/transactions_filters.dart';

TransactionEntry entry({
  DateTime? date,
  String type = 'expense',
  TransactionCategory category = const TransactionCategory(
    id: 'c1',
    name: 'Comida',
  ),
  TransactionAccount account = const TransactionAccount(
    id: 'a1',
    name: 'Santander',
  ),
}) {
  return TransactionEntry(
    id: 't1',
    type: type,
    amount: 10,
    date: date ?? DateTime(2026, 10, 14),
    category: category,
    account: account,
  );
}

void main() {
  group('query values', () {
    test('type filter round-trips through the query value', () {
      for (final filter in TransactionTypeFilter.values) {
        final value = TransactionsFilters.typeQueryValue(filter);

        expect(TransactionsFilters.typeFromQuery(value), filter);
      }
    });

    test('type filter: all is omitted and unknown values fall back to all', () {
      expect(
        TransactionsFilters.typeQueryValue(TransactionTypeFilter.all),
        isNull,
      );
      expect(
        TransactionsFilters.typeFromQuery(null),
        TransactionTypeFilter.all,
      );
      expect(
        TransactionsFilters.typeFromQuery('otro'),
        TransactionTypeFilter.all,
      );
    });

    test('date range round-trips through the query value', () {
      for (final range in TransactionDateRangeFilter.values) {
        final value = TransactionsFilters.rangeQueryValue(range);

        expect(TransactionsFilters.rangeFromQuery(value), range);
      }
    });

    test('date range: all is omitted and unknown values fall back to all', () {
      expect(
        TransactionsFilters.rangeQueryValue(TransactionDateRangeFilter.all),
        isNull,
      );
      expect(
        TransactionsFilters.rangeFromQuery('ayer'),
        TransactionDateRangeFilter.all,
      );
      expect(
        TransactionsFilters.rangeFromQuery(null),
        TransactionDateRangeFilter.all,
      );
    });

    test('date range uses the expected URL names', () {
      String? name(TransactionDateRangeFilter range) =>
          TransactionsFilters.rangeQueryValue(range);

      expect(name(TransactionDateRangeFilter.thisWeek), 'week');
      expect(name(TransactionDateRangeFilter.last7Days), 'last7');
      expect(name(TransactionDateRangeFilter.last15Days), 'last15');
    });
  });

  group('month handling', () {
    test('monthFromQuery reads YYYY-MM', () {
      expect(TransactionsFilters.monthFromQuery('2026-03'), DateTime(2026, 3));
      expect(TransactionsFilters.monthFromQuery('1999-12'), DateTime(1999, 12));
    });

    test('monthFromQuery falls back to the current month on bad input', () {
      final current = TransactionsFilters.currentMonth();

      const badValues = <String?>[
        null,
        '',
        'abc',
        '2026-13',
        '2026-00',
        '2026-1',
        '26-03',
        '2026-03-01',
        ' 2026-03',
      ];

      for (final value in badValues) {
        expect(
          TransactionsFilters.monthFromQuery(value),
          current,
          reason: 'value: $value',
        );
      }
    });

    test('currentMonth is the first day of the current month', () {
      final month = TransactionsFilters.currentMonth();

      expect(month.day, 1);
      expect(TransactionsFilters.isCurrentMonth(month), isTrue);
    });

    test('isCurrentMonth is false for other months and years', () {
      final current = TransactionsFilters.currentMonth();

      expect(
        TransactionsFilters.isCurrentMonth(
          DateTime(current.year, current.month - 1),
        ),
        isFalse,
      );
      expect(
        TransactionsFilters.isCurrentMonth(
          DateTime(current.year - 1, current.month),
        ),
        isFalse,
      );
    });

    test('monthQueryValue omits the current month', () {
      expect(
        TransactionsFilters.monthQueryValue(TransactionsFilters.currentMonth()),
        isNull,
      );
    });

    test('monthQueryValue pads the month', () {
      expect(
        TransactionsFilters.monthQueryValue(DateTime(2020, 1)),
        '2020-01',
      );
      expect(
        TransactionsFilters.monthQueryValue(DateTime(2020, 11)),
        '2020-11',
      );
    });

    test('monthQueryValue and monthFromQuery round-trip', () {
      final month = DateTime(2020, 7);

      expect(
        TransactionsFilters.monthFromQuery(
          TransactionsFilters.monthQueryValue(month),
        ),
        month,
      );
    });
  });

  group('matchesType', () {
    test('all lets everything through', () {
      expect(
        TransactionsFilters.matchesType(TransactionTypeFilter.all, entry()),
        isTrue,
      );
      expect(
        TransactionsFilters.matchesType(
          TransactionTypeFilter.all,
          entry(type: 'income'),
        ),
        isTrue,
      );
    });

    test('income and expense keep only their own type', () {
      final income = entry(type: 'income');
      final expense = entry(type: 'expense');

      expect(
        TransactionsFilters.matchesType(TransactionTypeFilter.income, income),
        isTrue,
      );
      expect(
        TransactionsFilters.matchesType(TransactionTypeFilter.income, expense),
        isFalse,
      );
      expect(
        TransactionsFilters.matchesType(TransactionTypeFilter.expense, expense),
        isTrue,
      );
      expect(
        TransactionsFilters.matchesType(TransactionTypeFilter.expense, income),
        isFalse,
      );
    });
  });

  group('matchesMonth', () {
    test('compares year and month only', () {
      final month = DateTime(2026, 10);
      bool inMonth(DateTime date) =>
          TransactionsFilters.matchesMonth(month, entry(date: date));

      expect(inMonth(DateTime(2026, 10, 31)), isTrue);
      expect(inMonth(DateTime(2026, 11, 1)), isFalse);
      expect(inMonth(DateTime(2025, 10, 14)), isFalse);
    });
  });

  group('matchesDateRange', () {
    // Wednesday 14 October 2026, early in the day.
    final now = DateTime(2026, 10, 14, 0, 1);

    bool matches(
      TransactionDateRangeFilter range,
      DateTime date, {
      DateTime? at,
    }) {
      return TransactionsFilters.matchesDateRange(
        range,
        entry(date: date),
        now: at ?? now,
      );
    }

    test('all matches any date', () {
      expect(matches(TransactionDateRangeFilter.all, DateTime(1999)), isTrue);
      expect(matches(TransactionDateRangeFilter.all, DateTime(2030)), isTrue);
    });

    test('today matches the whole day and nothing else', () {
      const range = TransactionDateRangeFilter.today;

      expect(matches(range, DateTime(2026, 10, 14, 23, 59)), isTrue);
      expect(matches(range, DateTime(2026, 10, 14)), isTrue);
      expect(matches(range, DateTime(2026, 10, 13, 23, 59)), isFalse);
      expect(matches(range, DateTime(2026, 10, 15)), isFalse);
    });

    test('thisWeek starts on Monday and ends today', () {
      const range = TransactionDateRangeFilter.thisWeek;

      expect(matches(range, DateTime(2026, 10, 12)), isTrue);
      expect(matches(range, DateTime(2026, 10, 14)), isTrue);
      expect(matches(range, DateTime(2026, 10, 11)), isFalse);
      expect(matches(range, DateTime(2026, 10, 15)), isFalse);
    });

    test('thisWeek on a Monday only includes that day', () {
      const range = TransactionDateRangeFilter.thisWeek;
      final monday = DateTime(2026, 10, 12, 9);

      expect(matches(range, DateTime(2026, 10, 12), at: monday), isTrue);
      expect(matches(range, DateTime(2026, 10, 11), at: monday), isFalse);
    });

    test('thisWeek on a Sunday reaches back to the Monday before', () {
      const range = TransactionDateRangeFilter.thisWeek;
      final sunday = DateTime(2026, 10, 18, 22);

      expect(matches(range, DateTime(2026, 10, 12), at: sunday), isTrue);
      expect(matches(range, DateTime(2026, 10, 11), at: sunday), isFalse);
    });

    test('last7Days covers today and the six days before', () {
      const range = TransactionDateRangeFilter.last7Days;

      expect(matches(range, DateTime(2026, 10, 8)), isTrue);
      expect(matches(range, DateTime(2026, 10, 14, 23, 59)), isTrue);
      expect(matches(range, DateTime(2026, 10, 7)), isFalse);
      expect(matches(range, DateTime(2026, 10, 15)), isFalse);
    });

    test('last15Days covers today and the fourteen days before', () {
      const range = TransactionDateRangeFilter.last15Days;

      expect(matches(range, DateTime(2026, 9, 30)), isTrue);
      expect(matches(range, DateTime(2026, 9, 29)), isFalse);
      expect(matches(range, DateTime(2026, 10, 15)), isFalse);
    });

    test('uses the current time when now is not given', () {
      final today = entry(date: DateTime.now());

      expect(
        TransactionsFilters.matchesDateRange(
          TransactionDateRangeFilter.today,
          today,
        ),
        isTrue,
      );
    });
  });

  group('keys and visible lists', () {
    const food = TransactionCategory(id: 'c1', name: 'Comida');
    const rent = TransactionCategory(id: 'c2', name: 'Alquiler');
    const noId = TransactionCategory(name: 'Sin categoría');

    test('categoryKeyOf and accountKeyOf prefer the id over the name', () {
      expect(TransactionsFilters.categoryKeyOf(entry(category: food)), 'c1');
      expect(
        TransactionsFilters.categoryKeyOf(entry(category: noId)),
        'Sin categoría',
      );
      expect(TransactionsFilters.accountKeyOf(entry()), 'a1');
      expect(
        TransactionsFilters.accountKeyOf(
          entry(account: const TransactionAccount(name: 'Sin cuenta')),
        ),
        'Sin cuenta',
      );
    });

    test('visibleCategories lists each category once, sorted by name', () {
      final result = TransactionsFilters.visibleCategories([
        entry(category: food),
        entry(category: rent),
        entry(category: food),
        entry(category: noId),
      ]);

      expect(
        result.map((c) => c.name),
        ['Alquiler', 'Comida', 'Sin categoría'],
      );
    });

    test('visibleAccounts lists each account once, sorted by name', () {
      const bbva = TransactionAccount(id: 'a2', name: 'BBVA');
      const santander = TransactionAccount(id: 'a1', name: 'Santander');

      final result = TransactionsFilters.visibleAccounts([
        entry(account: santander),
        entry(account: bbva),
        entry(account: santander),
      ]);

      expect(result.map((a) => a.name), ['BBVA', 'Santander']);
    });

    test('both lists are empty when there are no entries', () {
      expect(TransactionsFilters.visibleCategories(const []), isEmpty);
      expect(TransactionsFilters.visibleAccounts(const []), isEmpty);
    });
  });
}
