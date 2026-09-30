import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> saveOpeningBalance({
    required String userId,
    required String accountId,
    required int month,
    required int year,
    required double openingBalance,
  }) async {
    await _client.from('monthly_account_balances').upsert(
      {
        'user_id': userId,
        'account_id': accountId,
        'month': month,
        'year': year,
        'opening_balance': openingBalance,
      },
      onConflict: 'account_id,month,year',
    );
  }
}
