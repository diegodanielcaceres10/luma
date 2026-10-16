import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/monthly_opening_balance.dart';

class MonthlyBalanceService {
  final SupabaseClient _client;

  MonthlyBalanceService(this._client);

  /// IDs of the accounts that already have an opening balance for the month.
  Future<Set<String>> fetchExistingAccountIds({
    required int month,
    required int year,
  }) async {
    final rows = await _client
        .from('monthly_account_balances')
        .select('account_id')
        .eq('month', month)
        .eq('year', year);

    return (rows as List).map((row) => row['account_id'] as String).toSet();
  }

  /// Opening balance of every account that has a row for the month, by
  /// account id.
  Future<Map<String, double>> fetchOpeningBalancesByAccount({
    required int month,
    required int year,
  }) async {
    final rows = await _client
        .from('monthly_account_balances')
        .select('account_id, opening_balance')
        .eq('month', month)
        .eq('year', year);

    return {
      for (final row in rows as List)
        row['account_id'] as String:
            (row['opening_balance'] as num).toDouble(),
    };
  }

  /// Signed sum of `uncontrolled_expenses_total` across all accounts for the
  /// month (see `AccountViewModel.applyUncontrolledAdjustment`).
  Future<double> fetchUncontrolledExpensesTotal({
    required int month,
    required int year,
  }) async {
    final rows = await _client
        .from('monthly_account_balances')
        .select('uncontrolled_expenses_total')
        .eq('month', month)
        .eq('year', year);

    return (rows as List).fold<double>(
      0,
      (sum, row) =>
          sum + (row['uncontrolled_expenses_total'] as num).toDouble(),
    );
  }

  /// Months that have an opening balance row, per account, as [monthIndex]
  /// values.
  Future<Map<String, Set<int>>> fetchOpeningMonthsByAccount() async {
    final rows = await _client
        .from('monthly_account_balances')
        .select('account_id, month, year');

    final result = <String, Set<int>>{};
    for (final row in rows as List) {
      final accountId = row['account_id'] as String;
      final index = monthIndex(row['year'] as int, row['month'] as int);
      (result[accountId] ??= <int>{}).add(index);
    }
    return result;
  }

  /// Creates or replaces the row of the month. [uncontrolledExpensesTotal] is
  /// only written when given, so a plain call keeps the stored total.
  Future<void> saveOpeningBalance({
    required String userId,
    required String accountId,
    required int month,
    required int year,
    required double openingBalance,
    double? uncontrolledExpensesTotal,
  }) async {
    await _client.from('monthly_account_balances').upsert(
      {
        'user_id': userId,
        'account_id': accountId,
        'month': month,
        'year': year,
        'opening_balance': openingBalance,
        if (uncontrolledExpensesTotal != null)
          'uncontrolled_expenses_total': uncontrolledExpensesTotal,
      },
      onConflict: 'account_id,month,year',
    );
  }
}
