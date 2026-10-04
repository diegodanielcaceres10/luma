import '../../accounts/data/models/account.dart';

/// Days without a balance update after which an account is reported.
const int kStaleAccountDays = 5;

/// Active accounts whose balance was last updated [minDays] or more calendar
/// days before [today], paired with how many days that is.
///
/// Days are counted by calendar date, not by 24-hour blocks, so the account
/// shows up on the same morning regardless of the time it was last updated.
/// It keeps showing up every day until its balance changes again.
List<({Account account, int days})> staleAccounts({
  required List<Account> accounts,
  required DateTime today,
  int minDays = kStaleAccountDays,
}) {
  // UTC avoids DST shifts distorting the day difference.
  final todayDate = DateTime.utc(today.year, today.month, today.day);

  final result = <({Account account, int days})>[];
  for (final account in accounts) {
    if (!account.isActive) continue;

    final updated = account.balanceUpdatedAt;
    final updatedDate = DateTime.utc(updated.year, updated.month, updated.day);
    final days = todayDate.difference(updatedDate).inDays;

    if (days >= minDays) result.add((account: account, days: days));
  }
  return result;
}
