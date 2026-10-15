import '../../../../core/utils/app_clock.dart';
import '../../../transactions/data/models/transaction_entry.dart';
import '../../data/models/account.dart';
import '../../data/models/monthly_opening_balance.dart';

/// Rules for justifying a month that was never loaded for an account: which
/// accounts can be offered and how the amounts add up.
abstract final class ClosedMonthJustification {
  /// Whether [month] is before the current month.
  static bool isPastMonth(DateTime month, {DateTime? now}) {
    final today = now ?? nowLocal();
    return monthIndex(month.year, month.month) <
        monthIndex(today.year, today.month);
  }

  /// Accounts, in the order given, that can be justified for [month]: they
  /// already existed then (created that month or earlier; an unknown creation
  /// date counts as existing), have no opening balance for it and no
  /// movements in it. Nothing is offered for the current or a future month.
  static List<Account> eligibleAccounts({
    required DateTime month,
    required Iterable<Account> activeAccounts,
    required Map<String, Set<int>> openingMonthsByAccount,
    required Iterable<TransactionEntry> monthEntries,
    DateTime? now,
  }) {
    if (!isPastMonth(month, now: now)) return const [];

    final target = monthIndex(month.year, month.month);
    final accountsWithMovements = {
      for (final entry in monthEntries) entry.account.id,
    };

    return activeAccounts.where((account) {
      if (openingMonthsByAccount[account.id]?.contains(target) ?? false) {
        return false;
      }
      if (accountsWithMovements.contains(account.id)) return false;

      final createdAt = account.createdAt;
      return createdAt == null ||
          monthIndex(createdAt.year, createdAt.month) <= target;
    }).toList();
  }

  /// Closing balance minus opening balance, rounded to cents.
  static double difference({
    required double openingBalance,
    required double closingBalance,
  }) {
    return _roundCents(closingBalance - openingBalance);
  }

  /// Part of [difference] that [movementsTotal] (signed) doesn't cover; it is
  /// what stays as the month's uncontrolled total. Positive: an income is
  /// missing; negative: an expense is missing.
  static double unjustifiedRemainder({
    required double difference,
    required double movementsTotal,
  }) {
    return _roundCents(difference - movementsTotal);
  }

  static double _roundCents(double value) => (value * 100).round() / 100;
}
