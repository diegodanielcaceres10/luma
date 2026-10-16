import '../../../../core/utils/app_clock.dart';
import '../../data/models/transaction_entry.dart';

enum TransactionTypeFilter { all, income, expense }

enum TransactionDateRangeFilter { today, thisWeek, last7Days, last15Days, all }

/// Filters of the transaction history, kept apart from the screen so they
/// do not depend on widget state: URL query params, month handling and
/// the predicates that decide which movements are shown.
class TransactionsFilters {
  TransactionsFilters._();

  static TransactionTypeFilter typeFromQuery(String? value) {
    switch (value) {
      case 'income':
        return TransactionTypeFilter.income;
      case 'expense':
        return TransactionTypeFilter.expense;
      default:
        return TransactionTypeFilter.all;
    }
  }

  static String? typeQueryValue(TransactionTypeFilter filter) {
    switch (filter) {
      case TransactionTypeFilter.all:
        return null;
      case TransactionTypeFilter.income:
        return 'income';
      case TransactionTypeFilter.expense:
        return 'expense';
    }
  }

  static TransactionDateRangeFilter rangeFromQuery(String? value) {
    switch (value) {
      case 'today':
        return TransactionDateRangeFilter.today;
      case 'week':
        return TransactionDateRangeFilter.thisWeek;
      case 'last7':
        return TransactionDateRangeFilter.last7Days;
      case 'last15':
        return TransactionDateRangeFilter.last15Days;
      default:
        return TransactionDateRangeFilter.all;
    }
  }

  static String? rangeQueryValue(TransactionDateRangeFilter filter) {
    switch (filter) {
      case TransactionDateRangeFilter.all:
        return null;
      case TransactionDateRangeFilter.today:
        return 'today';
      case TransactionDateRangeFilter.thisWeek:
        return 'week';
      case TransactionDateRangeFilter.last7Days:
        return 'last7';
      case TransactionDateRangeFilter.last15Days:
        return 'last15';
    }
  }

  static DateTime currentMonth() {
    final now = nowLocal();
    return DateTime(now.year, now.month);
  }

  static bool isCurrentMonth(DateTime month) {
    final current = currentMonth();
    return month.year == current.year && month.month == current.month;
  }

  /// Parses 'YYYY-MM'; falls back to the current month if missing or
  /// invalid.
  static DateTime monthFromQuery(String? value) {
    if (value == null) return currentMonth();
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) return currentMonth();
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return currentMonth();
    return DateTime(year, month);
  }

  /// The current month is the default, so it is omitted from the URL.
  static String? monthQueryValue(DateTime month) {
    if (isCurrentMonth(month)) return null;
    final mm = month.month.toString().padLeft(2, '0');
    return '${month.year}-$mm';
  }

  /// Whether [t] passes the income/expense filter.
  static bool matchesType(TransactionTypeFilter filter, TransactionEntry t) {
    switch (filter) {
      case TransactionTypeFilter.all:
        return true;
      case TransactionTypeFilter.income:
        return t.isIncome;
      case TransactionTypeFilter.expense:
        return !t.isIncome;
    }
  }

  /// Whether [t] falls in [range]; pass the effective range (relative ranges
  /// only apply to the current month). [now] defaults to the current time.
  static bool matchesDateRange(
    TransactionDateRangeFilter range,
    TransactionEntry t, {
    DateTime? now,
  }) {
    final current = now ?? nowLocal();
    final today = DateTime(current.year, current.month, current.day);
    final txDate = DateTime(t.date.year, t.date.month, t.date.day);
    switch (range) {
      case TransactionDateRangeFilter.all:
        return true;
      case TransactionDateRangeFilter.today:
        return txDate == today;
      case TransactionDateRangeFilter.thisWeek:
        // Weeks start on Monday.
        final startOfWeek = _daysBefore(today, today.weekday - 1);
        return !txDate.isBefore(startOfWeek) && !txDate.isAfter(today);
      case TransactionDateRangeFilter.last7Days:
        final start = _daysBefore(today, 6);
        return !txDate.isBefore(start) && !txDate.isAfter(today);
      case TransactionDateRangeFilter.last15Days:
        final start = _daysBefore(today, 14);
        return !txDate.isBefore(start) && !txDate.isAfter(today);
    }
  }

  /// The calendar day [days] before [date] at midnight. Done by date, not by
  /// subtracting a Duration, which is off by an hour across a DST change.
  static DateTime _daysBefore(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day - days);

  /// Whether [t] belongs to the calendar month of [month].
  static bool matchesMonth(DateTime month, TransactionEntry t) =>
      t.date.year == month.year && t.date.month == month.month;

  static String categoryKeyOf(TransactionEntry t) =>
      t.category.id ?? t.category.name;

  static String accountKeyOf(TransactionEntry t) =>
      t.account.id ?? t.account.name;

  /// Categories with at least one transaction under the current type/date
  /// filters.
  static List<TransactionCategory> visibleCategories(
      List<TransactionEntry> typeFiltered) {
    final Map<String, TransactionCategory> byKey = {};
    for (final t in typeFiltered) {
      byKey[categoryKeyOf(t)] = t.category;
    }
    final list = byKey.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  static List<TransactionAccount> visibleAccounts(
      List<TransactionEntry> typeFiltered) {
    final Map<String, TransactionAccount> byKey = {};
    for (final t in typeFiltered) {
      byKey[accountKeyOf(t)] = t.account;
    }
    final list = byKey.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
}
