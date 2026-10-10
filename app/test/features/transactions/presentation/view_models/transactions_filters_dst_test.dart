import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/presentation/view_models/transactions_filters.dart';

// The relative ranges walk back from today. Across a daylight-saving change
// that walk must still land on a calendar day. These tests need a time zone
// that observes DST (run them with TZ=Europe/Madrid); elsewhere they skip.

bool shifts(DateTime a, DateTime b) => a.timeZoneOffset != b.timeZoneOffset;

final autumnShift = shifts(DateTime(2026, 10, 22), DateTime(2026, 10, 28));
final springShift = shifts(DateTime(2026, 3, 26), DateTime(2026, 4, 1));

const _noShiftReason = 'The local time zone has no DST change on these dates';

bool inRange(
  TransactionDateRangeFilter range,
  DateTime date,
  DateTime now,
) {
  final entry = TransactionEntry(
    id: 't1',
    type: 'expense',
    amount: 10,
    date: date,
    category: const TransactionCategory(id: 'c1', name: 'Comida'),
    account: const TransactionAccount(id: 'a1', name: 'Santander'),
  );

  return TransactionsFilters.matchesDateRange(range, entry, now: now);
}

void main() {
  group('matchesDateRange after the autumn clock change', () {
    // Clocks go back on Sunday 25 October 2026 in Europe.
    final now = DateTime(2026, 10, 28, 12);

    test(
      'last7Days still includes the oldest day',
      () {
        const range = TransactionDateRangeFilter.last7Days;

        expect(inRange(range, DateTime(2026, 10, 22), now), isTrue);
        expect(inRange(range, DateTime(2026, 10, 21), now), isFalse);
      },
      skip: autumnShift ? false : _noShiftReason,
    );

    test(
      'last15Days still includes the oldest day',
      () {
        const range = TransactionDateRangeFilter.last15Days;

        expect(inRange(range, DateTime(2026, 10, 14), now), isTrue);
        expect(inRange(range, DateTime(2026, 10, 13), now), isFalse);
      },
      skip: autumnShift ? false : _noShiftReason,
    );

    test(
      'thisWeek is not affected',
      () {
        const range = TransactionDateRangeFilter.thisWeek;

        expect(inRange(range, DateTime(2026, 10, 26), now), isTrue);
        expect(inRange(range, DateTime(2026, 10, 25), now), isFalse);
      },
      skip: autumnShift ? false : _noShiftReason,
    );
  });

  group('matchesDateRange after the spring clock change', () {
    // Clocks go forward on Sunday 29 March 2026 in Europe.
    final now = DateTime(2026, 4, 1, 12);

    test(
      'last7Days covers exactly seven calendar days',
      () {
        const range = TransactionDateRangeFilter.last7Days;

        expect(inRange(range, DateTime(2026, 3, 26), now), isTrue);
        expect(inRange(range, DateTime(2026, 3, 25), now), isFalse);
      },
      skip: springShift ? false : _noShiftReason,
    );
  });
}
